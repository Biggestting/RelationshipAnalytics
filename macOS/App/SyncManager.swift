import Foundation
import Combine

@MainActor
final class SyncManager: ObservableObject {
    @Published var contacts: [ContactProfile] = []
    @Published var contactStats: [String: ContactAnalyticsBundle] = [:]
    @Published var isLoading = false
    @Published var isFetchingContacts = false
    @Published var error: String?
    @Published var lastSync: Date?
    @Published var syncProgress: String = ""
    @Published var processedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var selectedContactIds: Set<String> = []

    private let rankingService = RankingService()

    var lastSyncFormatted: String {
        guard let lastSync else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }

    var selectedCount: Int { selectedContactIds.count }

    // MARK: - Step 1: Fetch contact list (fast, no stats)

    func fetchContactList() async {
        isFetchingContacts = true
        error = nil
        syncProgress = "Loading contacts..."

        do {
            let fetched = try await Task.detached(priority: .userInitiated) { () -> [ContactProfile] in
                let service = MessageDatabaseService()
                try service.open()
                defer { service.close() }
                return try service.fetchContacts()
            }.value

            contacts = fetched
            syncProgress = "\(fetched.count) contacts found. Select contacts to sync."
        } catch {
            self.error = error.localizedDescription
            syncProgress = "Error: \(error.localizedDescription)"
        }

        isFetchingContacts = false
    }

    // MARK: - Select helpers

    func selectAll() {
        selectedContactIds = Set(contacts.map { $0.id })
    }

    func deselectAll() {
        selectedContactIds.removeAll()
    }

    func toggleContact(_ id: String) {
        if selectedContactIds.contains(id) {
            selectedContactIds.remove(id)
        } else {
            selectedContactIds.insert(id)
        }
    }

    // MARK: - Step 2: Sync selected contacts only

    func syncSelected() async {
        let idsToSync = selectedContactIds
        guard !idsToSync.isEmpty else {
            syncProgress = "No contacts selected."
            return
        }

        isLoading = true
        error = nil
        processedCount = 0
        totalCount = idsToSync.count
        syncProgress = "Syncing \(idsToSync.count) contacts..."

        let contactsToSync = contacts.filter { idsToSync.contains($0.id) }

        let result: SyncResult
        do {
            result = try await Task.detached(priority: .userInitiated) {
                try await self.performDatabaseWork(for: contactsToSync)
            }.value
        } catch {
            self.error = error.localizedDescription
            syncProgress = "Error: \(error.localizedDescription)"
            isLoading = false
            return
        }

        // Calculate rankings
        syncProgress = "Calculating rankings..."
        var bundles = result.bundles
        let allWeeklyCounts = result.weeklyCounts

        for (id, bundle) in bundles {
            let rankData = rankingService.calculateRankHistory(
                contactId: id,
                allContactStats: allWeeklyCounts
            )
            bundles[id] = ContactAnalyticsBundle(
                contact: bundle.contact,
                messageStats: bundle.messageStats,
                callStats: bundle.callStats,
                rankData: rankData
            )
        }

        // Merge with existing stats (don't overwrite unselected contacts)
        for (id, bundle) in bundles {
            contactStats[id] = bundle
        }

        syncProgress = "Saving..."
        saveLocally(bundles: contactStats)

        lastSync = Date()
        UserDefaults.standard.set(Date(), forKey: "lastMacSync")
        syncProgress = "Done! \(idsToSync.count) contacts synced."
        isLoading = false
    }

    /// Sync ALL contacts (convenience)
    func syncAll() async {
        selectAll()
        await syncSelected()
    }

    // MARK: - Database Work (background thread)

    nonisolated private func performDatabaseWork(for contactsToSync: [ContactProfile]) async throws -> SyncResult {
        let messageService = MessageDatabaseService()
        let callLogService = CallLogService()

        try messageService.open()
        defer { messageService.close() }

        var callLogAvailable = false
        do {
            try callLogService.open()
            callLogAvailable = true
        } catch {
            await MainActor.run {
                self.syncProgress = "Call history not available. Messages only..."
            }
        }
        defer { if callLogAvailable { callLogService.close() } }

        var bundles: [String: ContactAnalyticsBundle] = [:]
        var allWeeklyCounts: [(id: String, weeklyMessageCounts: [Date: Int])] = []
        let rankingService = RankingService()

        for (index, contact) in contactsToSync.enumerated() {
            await MainActor.run {
                self.processedCount = index + 1
                self.syncProgress = "[\(index + 1)/\(contactsToSync.count)] \(contact.name)..."
            }

            let messageStats = try messageService.fetchMessageStats(handleId: contact.id)

            let callStats: CallStats
            if callLogAvailable, let phone = contact.phoneNumber {
                callStats = try callLogService.fetchCallStats(phoneNumber: phone)
            } else {
                callStats = Self.emptyCallStats(contactId: contact.id)
            }

            let weekly = rankingService.weeklyMessageCounts(from: messageStats.messageActivity)
            allWeeklyCounts.append((id: contact.id, weeklyMessageCounts: weekly))

            bundles[contact.id] = ContactAnalyticsBundle(
                contact: contact,
                messageStats: messageStats,
                callStats: callStats,
                rankData: RankData(contactId: contact.id, currentRank: 0, bestRank: 0, currentRankDate: Date(), bestRankDate: Date(), rankHistory: [])
            )
        }

        return SyncResult(contacts: contactsToSync, bundles: bundles, weeklyCounts: allWeeklyCounts)
    }

    // MARK: - Local Storage

    private func saveLocally(bundles: [String: ContactAnalyticsBundle]) {
        let encoder = JSONEncoder()
        let syncedContacts = bundles.values.map { $0.contact }

        if let data = try? encoder.encode(syncedContacts) {
            UserDefaults.standard.set(data, forKey: "syncedContacts")
        }

        for (id, bundle) in bundles {
            if let msgData = try? encoder.encode(bundle.messageStats) {
                UserDefaults.standard.set(msgData, forKey: "stats_msg_\(id)")
            }
            if let callData = try? encoder.encode(bundle.callStats) {
                UserDefaults.standard.set(callData, forKey: "stats_call_\(id)")
            }
            if let rankData = try? encoder.encode(bundle.rankData) {
                UserDefaults.standard.set(rankData, forKey: "stats_rank_\(id)")
            }
        }
        UserDefaults.standard.set(Date(), forKey: "lastLocalSync")
    }

    func loadLocal() -> [String: ContactAnalyticsBundle] {
        let decoder = JSONDecoder()
        guard let contactsData = UserDefaults.standard.data(forKey: "syncedContacts"),
              let savedContacts = try? decoder.decode([ContactProfile].self, from: contactsData) else { return [:] }

        var bundles: [String: ContactAnalyticsBundle] = [:]
        for contact in savedContacts {
            let msgStats = UserDefaults.standard.data(forKey: "stats_msg_\(contact.id)")
                .flatMap { try? decoder.decode(MessageStats.self, from: $0) }
            let callStats = UserDefaults.standard.data(forKey: "stats_call_\(contact.id)")
                .flatMap { try? decoder.decode(CallStats.self, from: $0) }
            let rankData = UserDefaults.standard.data(forKey: "stats_rank_\(contact.id)")
                .flatMap { try? decoder.decode(RankData.self, from: $0) }
            if let msg = msgStats {
                bundles[contact.id] = ContactAnalyticsBundle(
                    contact: contact, messageStats: msg,
                    callStats: callStats ?? Self.emptyCallStats(contactId: contact.id),
                    rankData: rankData ?? RankData(contactId: contact.id, currentRank: 0, bestRank: 0, currentRankDate: Date(), bestRankDate: Date(), rankHistory: [])
                )
            }
        }
        return bundles
    }

    nonisolated static func emptyCallStats(contactId: String) -> CallStats {
        CallStats(
            contactId: contactId, totalCallTime: 0, totalCalls: 0, answeredCalls: 0,
            averageCallDuration: 0, lastAnsweredDate: nil, monthlyCallData: [],
            callRecords: [], hourlyCallPattern: [],
            missedStats: MissedCallStats(youMissed: 0, theyMissed: 0, totalMissed: 0, totalAnswered: 0, yourAnswerRate: 100, theirAnswerRate: 100, longestUnansweredStreak: 0),
            faceTimeStats: FaceTimeStats(videoCallCount: 0, audioCallCount: 0, regularCallCount: 0, videoTotalDuration: 0, audioFTDuration: 0, regularDuration: 0, lastFaceTimeDate: nil)
        )
    }
}

private struct SyncResult: Sendable {
    let contacts: [ContactProfile]
    let bundles: [String: ContactAnalyticsBundle]
    let weeklyCounts: [(id: String, weeklyMessageCounts: [Date: Int])]
}
