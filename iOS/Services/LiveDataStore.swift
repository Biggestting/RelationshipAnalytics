import Foundation

/// Persistent local store for all live-tracked data.
/// Accumulates call events and message counts from install date forward.
/// Stored as JSON in the app's documents directory.
final class LiveDataStore {
    static let shared = LiveDataStore()

    private let fileURL: URL
    private var data: LiveData

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("live_data.json")
        data = LiveDataStore.load(from: fileURL)
    }

    // MARK: - Call Tracking

    func logCall(_ call: TrackedCall) {
        data.calls.append(call)
        save()
    }

    func getCalls(for phoneNumber: String) -> [TrackedCall] {
        let normalized = normalizePhone(phoneNumber)
        return data.calls.filter { normalizePhone($0.phoneNumber) == normalized }
    }

    func getAllCalls() -> [TrackedCall] {
        data.calls
    }

    // MARK: - Message Notification Tracking

    func logMessageNotification(from sender: String, at date: Date = Date()) {
        let key = sender.lowercased()
        var entry = data.messageCounts[key] ?? MessageCountEntry(contactName: sender, received: 0, lastSeen: date)
        entry.received += 1
        entry.lastSeen = date
        data.messageCounts[key] = entry
        save()
    }

    func logMessageSent(to contact: String, at date: Date = Date()) {
        let key = contact.lowercased()
        var entry = data.messageCounts[key] ?? MessageCountEntry(contactName: contact, received: 0, lastSeen: date)
        entry.sent += 1
        entry.lastSeen = date
        data.messageCounts[key] = entry
        save()
    }

    func getMessageCounts(for contact: String) -> MessageCountEntry? {
        data.messageCounts[contact.lowercased()]
    }

    func getAllMessageCounts() -> [String: MessageCountEntry] {
        data.messageCounts
    }

    // MARK: - Shortcuts Import

    func importShortcutsData(_ messages: [ShortcutsMessage]) {
        for msg in messages {
            let key = msg.contact.lowercased()
            var entry = data.shortcutsImports[key] ?? ShortcutsImportEntry(contactName: msg.contact, messages: [])
            entry.messages.append(msg)
            data.shortcutsImports[key] = entry
        }
        save()
    }

    func getShortcutsImport(for contact: String) -> ShortcutsImportEntry? {
        data.shortcutsImports[contact.lowercased()]
    }

    func getAllShortcutsImports() -> [String: ShortcutsImportEntry] {
        data.shortcutsImports
    }

    // MARK: - Tracking start date

    var trackingStartDate: Date {
        data.installDate
    }

    // MARK: - Persistence

    private func save() {
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: fileURL)
        }
    }

    private static func load(from url: URL) -> LiveData {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(LiveData.self, from: data) else {
            return LiveData(installDate: Date(), calls: [], messageCounts: [:], shortcutsImports: [:])
        }
        return decoded
    }

    private func normalizePhone(_ phone: String) -> String {
        phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression).suffix(10).description
    }
}

// MARK: - Data Models

struct LiveData: Codable {
    let installDate: Date
    var calls: [TrackedCall]
    var messageCounts: [String: MessageCountEntry]
    var shortcutsImports: [String: ShortcutsImportEntry]
}

struct TrackedCall: Codable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)-\(phoneNumber)" }
    let phoneNumber: String
    let contactName: String?
    let date: Date
    let duration: TimeInterval
    let wasIncoming: Bool
    let wasAnswered: Bool
    let isFaceTime: Bool
}

struct MessageCountEntry: Codable {
    let contactName: String
    var sent: Int = 0
    var received: Int
    var lastSeen: Date
    var dailyCounts: [String: DayCount] = [:]

    struct DayCount: Codable {
        var sent: Int = 0
        var received: Int = 0
    }
}

struct ShortcutsMessage: Codable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)-\(contact)" }
    let contact: String
    let text: String
    let date: Date
    let isFromMe: Bool
}

struct ShortcutsImportEntry: Codable {
    let contactName: String
    var messages: [ShortcutsMessage]
}
