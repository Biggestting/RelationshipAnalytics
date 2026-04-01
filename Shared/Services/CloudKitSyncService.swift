import Foundation
import CloudKit

/// Syncs analytics data between macOS and iOS via CloudKit.
/// Both apps must use the same CloudKit container identifier.
final class CloudKitSyncService {
    static let containerIdentifier = "iCloud.com.relationshipanalytics"

    private let container: CKContainer
    private let privateDB: CKDatabase

    init() {
        container = CKContainer(identifier: Self.containerIdentifier)
        privateDB = container.privateCloudDatabase
    }

    // MARK: - Save (macOS → CloudKit)

    func saveContactStats(
        contact: ContactProfile,
        messageStats: MessageStats,
        callStats: CallStats,
        rankData: RankData
    ) async throws {
        let record = CKRecord(recordType: "ContactAnalytics", recordID: CKRecord.ID(recordName: contact.id))

        // Contact info
        record["name"] = contact.name
        record["initials"] = contact.initials
        record["talkingSince"] = contact.talkingSince as NSDate
        record["phoneNumber"] = contact.phoneNumber

        // Encode stats as JSON data
        let encoder = JSONEncoder()
        if let messageData = try? encoder.encode(messageStats) {
            record["messageStats"] = messageData as NSData
        }
        if let callData = try? encoder.encode(callStats) {
            record["callStats"] = callData as NSData
        }
        if let rankDataEncoded = try? encoder.encode(rankData) {
            record["rankData"] = rankDataEncoded as NSData
        }

        record["lastSynced"] = Date() as NSDate

        try await privateDB.save(record)
    }

    // MARK: - Fetch (CloudKit → iOS)

    func fetchAllContactAnalytics() async throws -> [ContactAnalyticsBundle] {
        let query = CKQuery(recordType: "ContactAnalytics", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "lastSynced", ascending: false)]

        let results = try await privateDB.records(matching: query)
        let decoder = JSONDecoder()

        var bundles: [ContactAnalyticsBundle] = []

        for (_, result) in results.matchResults {
            guard let record = try? result.get() else { continue }

            let contact = ContactProfile(
                id: record.recordID.recordName,
                name: record["name"] as? String ?? "Unknown",
                initials: record["initials"] as? String ?? "?",
                talkingSince: record["talkingSince"] as? Date ?? Date(),
                phoneNumber: record["phoneNumber"] as? String,
                email: nil
            )

            let messageStats: MessageStats? = {
                guard let data = record["messageStats"] as? Data else { return nil }
                return try? decoder.decode(MessageStats.self, from: data)
            }()

            let callStats: CallStats? = {
                guard let data = record["callStats"] as? Data else { return nil }
                return try? decoder.decode(CallStats.self, from: data)
            }()

            let rankData: RankData? = {
                guard let data = record["rankData"] as? Data else { return nil }
                return try? decoder.decode(RankData.self, from: data)
            }()

            if let messageStats, let callStats, let rankData {
                bundles.append(ContactAnalyticsBundle(
                    contact: contact,
                    messageStats: messageStats,
                    callStats: callStats,
                    rankData: rankData
                ))
            }
        }

        return bundles
    }

    // MARK: - Subscribe to changes

    func subscribeToChanges() async throws {
        let subscription = CKQuerySubscription(
            recordType: "ContactAnalytics",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification

        try await privateDB.save(subscription)
    }
}

struct ContactAnalyticsBundle: Identifiable {
    var id: String { contact.id }
    let contact: ContactProfile
    let messageStats: MessageStats
    let callStats: CallStats
    let rankData: RankData
}
