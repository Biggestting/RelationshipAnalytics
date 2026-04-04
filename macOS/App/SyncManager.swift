import Foundation
import Combine

@MainActor
final class SyncManager: ObservableObject {
    @Published var contacts: [ContactProfile] = []
    @Published var contactStats: [String: ContactAnalyticsBundle] = [:]
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastSync: Date?
    @Published var syncProgress: String = ""
    @Published var processedCount: Int = 0
    @Published var totalCount: Int = 0

    private let messageService = MessageDatabaseService()
    private let callLogService = CallLogService()
    private let rankingService = RankingService()
    private let cloudKit = CloudKitSyncService()

    var lastSyncFormatted: String {
        guard let lastSync else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }

    func syncAll() async {
        isLoading = true
        error = nil
        processedCount = 0
        syncProgress = "Opening iMessage database..."

        do {
            // STEP 1: Read iMessage database
            try messageService.open()
            defer { messageService.close() }

            syncProgress = "Fetching contacts..."
            contacts = try messageService.fetchContacts()
            totalCount = contacts.count

            syncProgress = "Found \(contacts.count) contacts. Processing..."

            // STEP 2: Open call history database
            var callLogAvailable = false
            do {
                try callLogService.open()
                callLogAvailable = true
            } catch {
                syncProgress = "Call history not available (need Full Disk Access). Continuing with messages only..."
            }
            defer { if callLogAvailable { callLogService.close() } }

            // STEP 3: Process each contact
            var allWeeklyCounts: [(id: String, weeklyMessageCounts: [Date: Int])] = []
            var bundles: [String: ContactAnalyticsBundle] = [:]

            for (index, contact) in contacts.enumerated() {
                processedCount = index + 1
                syncProgress = "[\(index + 1)/\(contacts.count)] \(contact.name)..."

                // Message stats
                let messageStats = try messageService.fetchMessageStats(handleId: contact.id)

                // Call stats
                let callStats: CallStats
                if callLogAvailable, let phone = contact.phoneNumber {
                    callStats = try callLogService.fetchCallStats(phoneNumber: phone)
                } else {
                    callStats = emptyCallStats(contactId: contact.id)
                }

                // Weekly counts for ranking
                let weekly = rankingService.weeklyMessageCounts(from: messageStats.messageActivity)
                allWeeklyCounts.append((id: contact.id, weeklyMessageCounts: weekly))

                bundles[contact.id] = ContactAnalyticsBundle(
                    contact: contact,
                    messageStats: messageStats,
                    callStats: callStats,
                    rankData: RankData(contactId: contact.id, currentRank: 0, bestRank: 0, currentRankDate: Date(), bestRankDate: Date(), rankHistory: [])
                )
            }

            // STEP 4: Calculate rankings across all contacts
            syncProgress = "Calculating rankings..."
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

            contactStats = bundles

            // STEP 5: Save locally
            syncProgress = "Saving locally..."
            saveLocally(bundles: bundles)

            // STEP 6: Sync to CloudKit
            syncProgress = "Syncing to iCloud..."
            var cloudErrors: [String] = []
            for (_, bundle) in bundles {
                do {
                    try await cloudKit.saveContactStats(
                        contact: bundle.contact,
                        messageStats: bundle.messageStats,
                        callStats: bundle.callStats,
                        rankData: bundle.rankData
                    )
                } catch {
                    cloudErrors.append("\(bundle.contact.name): \(error.localizedDescription)")
                }
            }

            lastSync = Date()
            UserDefaults.standard.set(Date(), forKey: "lastMacSync")

            if cloudErrors.isEmpty {
                syncProgress = "Sync complete! \(contacts.count) contacts synced to iCloud."
            } else {
                syncProgress = "Synced \(contacts.count - cloudErrors.count)/\(contacts.count) to iCloud. \(cloudErrors.count) failed."
                // Still mark as success — local data is saved
            }

        } catch {
            self.error = error.localizedDescription
            syncProgress = "Error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Local Storage

    private func saveLocally(bundles: [String: ContactAnalyticsBundle]) {
        let encoder = JSONEncoder()

        // Save contacts list
        if let data = try? encoder.encode(contacts) {
            UserDefaults.standard.set(data, forKey: "syncedContacts")
        }

        // Save each contact's full stats
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
              let contacts = try? decoder.decode([ContactProfile].self, from: contactsData) else {
            return [:]
        }

        var bundles: [String: ContactAnalyticsBundle] = [:]
        for contact in contacts {
            let msgStats: MessageStats? = UserDefaults.standard.data(forKey: "stats_msg_\(contact.id)")
                .flatMap { try? decoder.decode(MessageStats.self, from: $0) }
            let callStats: CallStats? = UserDefaults.standard.data(forKey: "stats_call_\(contact.id)")
                .flatMap { try? decoder.decode(CallStats.self, from: $0) }
            let rankData: RankData? = UserDefaults.standard.data(forKey: "stats_rank_\(contact.id)")
                .flatMap { try? decoder.decode(RankData.self, from: $0) }

            if let msg = msgStats {
                bundles[contact.id] = ContactAnalyticsBundle(
                    contact: contact,
                    messageStats: msg,
                    callStats: callStats ?? emptyCallStats(contactId: contact.id),
                    rankData: rankData ?? RankData(contactId: contact.id, currentRank: 0, bestRank: 0, currentRankDate: Date(), bestRankDate: Date(), rankHistory: [])
                )
            }
        }
        return bundles
    }

    private func emptyCallStats(contactId: String) -> CallStats {
        CallStats(
            contactId: contactId, totalCallTime: 0, totalCalls: 0, answeredCalls: 0,
            averageCallDuration: 0, lastAnsweredDate: nil, monthlyCallData: [],
            callRecords: [], hourlyCallPattern: [],
            missedStats: MissedCallStats(youMissed: 0, theyMissed: 0, totalMissed: 0, totalAnswered: 0, yourAnswerRate: 100, theirAnswerRate: 100, longestUnansweredStreak: 0),
            faceTimeStats: FaceTimeStats(videoCallCount: 0, audioCallCount: 0, regularCallCount: 0, videoTotalDuration: 0, audioFTDuration: 0, regularDuration: 0, lastFaceTimeDate: nil)
        )
    }
}
