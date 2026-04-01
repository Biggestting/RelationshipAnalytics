import Foundation
import Combine

@MainActor
final class SyncManager: ObservableObject {
    @Published var contacts: [ContactProfile] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastSync: Date?
    @Published var syncProgress: String = ""

    private let messageService = MessageDatabaseService()
    private let callLogService = CallLogService()
    private let rankingService = RankingService()

    var lastSyncFormatted: String {
        guard let lastSync else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }

    func syncAll() async {
        isLoading = true
        error = nil
        syncProgress = "Opening iMessage database..."

        do {
            try messageService.open()
            defer { messageService.close() }

            syncProgress = "Fetching contacts..."
            contacts = try messageService.fetchContacts()

            syncProgress = "Processing \(contacts.count) contacts..."

            // Process stats for each contact
            var allStats: [(id: String, weeklyMessageCounts: [Date: Int])] = []

            for (index, contact) in contacts.enumerated() {
                syncProgress = "Analyzing \(contact.name) (\(index + 1)/\(contacts.count))..."
                let stats = try messageService.fetchMessageStats(handleId: contact.id)
                let weekly = rankingService.weeklyMessageCounts(from: stats.messageActivity)
                allStats.append((id: contact.id, weeklyMessageCounts: weekly))
            }

            // Save to shared storage (UserDefaults suite or CloudKit)
            saveToSharedStorage(contacts: contacts)

            lastSync = Date()
            syncProgress = "Sync complete!"
        } catch {
            self.error = error.localizedDescription
            syncProgress = "Error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func saveToSharedStorage(contacts: [ContactProfile]) {
        // Save to app group UserDefaults for sharing between macOS and iOS
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(contacts) {
            UserDefaults.standard.set(data, forKey: "syncedContacts")
        }
    }
}
