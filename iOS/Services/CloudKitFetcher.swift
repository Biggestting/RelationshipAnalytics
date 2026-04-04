import Foundation

/// Fetches analytics data from CloudKit (synced by macOS companion).
/// Called on iOS app launch to pull the latest data.
@MainActor
final class CloudKitFetcher: ObservableObject {
    static let shared = CloudKitFetcher()

    @Published var bundles: [ContactAnalyticsBundle] = []
    @Published var isFetching = false
    @Published var lastFetch: Date?
    @Published var error: String?

    private let cloudKit = CloudKitSyncService()

    private init() {
        lastFetch = UserDefaults.standard.object(forKey: "lastCloudKitFetch") as? Date
    }

    func fetchIfNeeded() async {
        // Fetch if we've never fetched or it's been >30 minutes
        let shouldFetch: Bool
        if let last = lastFetch {
            shouldFetch = Date().timeIntervalSince(last) > 1800
        } else {
            shouldFetch = true
        }

        if shouldFetch {
            await fetch()
        }
    }

    func fetch() async {
        guard !isFetching else { return }
        isFetching = true
        error = nil

        do {
            bundles = try await cloudKit.fetchAllContactAnalytics()
            lastFetch = Date()
            UserDefaults.standard.set(Date(), forKey: "lastCloudKitFetch")

            // Cache locally so we have data even offline
            cacheLocally()
        } catch {
            self.error = error.localizedDescription

            // Load from cache if CloudKit fails
            loadFromCache()
        }

        isFetching = false
    }

    private func cacheLocally() {
        let encoder = JSONEncoder()
        for bundle in bundles {
            if let data = try? encoder.encode(bundle.contact) {
                UserDefaults.standard.set(data, forKey: "ck_contact_\(bundle.contact.id)")
            }
            if let data = try? encoder.encode(bundle.messageStats) {
                UserDefaults.standard.set(data, forKey: "ck_msg_\(bundle.contact.id)")
            }
            if let data = try? encoder.encode(bundle.callStats) {
                UserDefaults.standard.set(data, forKey: "ck_call_\(bundle.contact.id)")
            }
            if let data = try? encoder.encode(bundle.rankData) {
                UserDefaults.standard.set(data, forKey: "ck_rank_\(bundle.contact.id)")
            }
        }
        // Save the contact IDs list
        let ids = bundles.map { $0.contact.id }
        UserDefaults.standard.set(ids, forKey: "ck_contact_ids")
    }

    private func loadFromCache() {
        let decoder = JSONDecoder()
        guard let ids = UserDefaults.standard.array(forKey: "ck_contact_ids") as? [String] else { return }

        var cached: [ContactAnalyticsBundle] = []
        for id in ids {
            guard let contactData = UserDefaults.standard.data(forKey: "ck_contact_\(id)"),
                  let contact = try? decoder.decode(ContactProfile.self, from: contactData),
                  let msgData = UserDefaults.standard.data(forKey: "ck_msg_\(id)"),
                  let msgStats = try? decoder.decode(MessageStats.self, from: msgData) else { continue }

            let callStats = UserDefaults.standard.data(forKey: "ck_call_\(id)")
                .flatMap { try? decoder.decode(CallStats.self, from: $0) }
            let rankData = UserDefaults.standard.data(forKey: "ck_rank_\(id)")
                .flatMap { try? decoder.decode(RankData.self, from: $0) }

            cached.append(ContactAnalyticsBundle(
                contact: contact,
                messageStats: msgStats,
                callStats: callStats ?? emptyCallStats(),
                rankData: rankData ?? emptyRankData()
            ))
        }
        bundles = cached
    }

    private func emptyCallStats() -> CallStats {
        CallStats(contactId: "", totalCallTime: 0, totalCalls: 0, answeredCalls: 0, averageCallDuration: 0, lastAnsweredDate: nil, monthlyCallData: [], callRecords: [], hourlyCallPattern: [], missedStats: MissedCallStats(youMissed: 0, theyMissed: 0, totalMissed: 0, totalAnswered: 0, yourAnswerRate: 100, theirAnswerRate: 100, longestUnansweredStreak: 0), faceTimeStats: FaceTimeStats(videoCallCount: 0, audioCallCount: 0, regularCallCount: 0, videoTotalDuration: 0, audioFTDuration: 0, regularDuration: 0, lastFaceTimeDate: nil))
    }

    private func emptyRankData() -> RankData {
        RankData(contactId: "", currentRank: 0, bestRank: 0, currentRankDate: Date(), bestRankDate: Date(), rankHistory: [])
    }
}
