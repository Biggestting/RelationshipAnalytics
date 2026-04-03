import AppIntents
import Foundation

/// App Intent that receives message data from iOS Shortcuts.
/// Users can call this from any Shortcut to pipe message data into the app.
struct ImportMessagesIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Messages"
    static var description = IntentDescription("Import message history from a contact into Relationship Analytics")
    static var openAppWhenRun = true

    @Parameter(title: "Contact Name")
    var contactName: String

    @Parameter(title: "Messages JSON")
    var messagesJSON: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let data = messagesJSON.data(using: .utf8) else {
            return .result(value: "Error: Invalid data")
        }

        guard let messages = try? JSONDecoder().decode([ShortcutsMessageDTO].self, from: data) else {
            return .result(value: "Error: Could not parse messages")
        }

        let converted = messages.compactMap { dto -> ShortcutsMessage? in
            guard let date = parseDate(dto.date) else { return nil }
            return ShortcutsMessage(
                contact: dto.sender.isEmpty ? contactName : dto.sender,
                text: dto.text ?? "",
                date: date,
                isFromMe: dto.is_from_me ?? false
            )
        }

        LiveDataStore.shared.importShortcutsData(converted)

        return .result(value: "Imported \(converted.count) messages from \(contactName)")
    }

    private func parseDate(_ string: String) -> Date? {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "MMM d, yyyy 'at' h:mm a",
            "MM/dd/yyyy HH:mm",
        ]
        for fmt in formats {
            let f = DateFormatter()
            f.dateFormat = fmt
            f.locale = Locale(identifier: "en_US_POSIX")
            if let date = f.date(from: string) { return date }
        }
        return nil
    }
}

private struct ShortcutsMessageDTO: Decodable {
    let sender: String
    let text: String?
    let date: String
    let is_from_me: Bool?
}

/// Simpler intent: just log a single message event
struct LogMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Message"
    static var description = IntentDescription("Log a message sent or received for tracking")

    @Parameter(title: "Contact Name")
    var contactName: String

    @Parameter(title: "Direction", default: "received")
    var direction: String

    func perform() async throws -> some IntentResult {
        if direction.lowercased() == "sent" {
            MessageTracker.shared.logSentMessage(to: contactName)
        } else {
            MessageTracker.shared.logReceivedMessage(from: contactName)
        }
        return .result()
    }
}

/// Intent to log a call event
struct LogCallIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Call"
    static var description = IntentDescription("Log a phone call for tracking")

    @Parameter(title: "Contact Name")
    var contactName: String

    @Parameter(title: "Phone Number")
    var phoneNumber: String

    @Parameter(title: "Duration (seconds)", default: 0)
    var duration: Int

    @Parameter(title: "Was Incoming", default: true)
    var wasIncoming: Bool

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let call = TrackedCall(
            phoneNumber: phoneNumber,
            contactName: contactName,
            date: Date(),
            duration: TimeInterval(duration),
            wasIncoming: wasIncoming,
            wasAnswered: duration > 0,
            isFaceTime: false
        )
        LiveDataStore.shared.logCall(call)
        return .result(value: "Logged \(duration)s call with \(contactName)")
    }
}
