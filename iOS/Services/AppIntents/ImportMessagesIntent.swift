import AppIntents
import Foundation

/// App Intent that receives message data from iOS Shortcuts.
///
/// Usage from Shortcuts:
/// 1. "Find All Messages" (no filter) → get all messages
/// 2. Repeat with each → build JSON
/// 3. Pass JSON string to this intent
///
/// The intent parses the JSON, groups by contact, and imports all at once.
struct ImportMessagesIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Messages"
    static var description = IntentDescription("Import all message history into Relationship Analytics. Works with all contacts at once — no need to select individual contacts.")
    static var openAppWhenRun = true

    @Parameter(title: "Messages JSON", description: "JSON array of messages. Each message needs: sender, text, date, is_from_me fields.")
    var messagesJSON: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let data = messagesJSON.data(using: .utf8) else {
            return .result(value: "Error: Invalid data encoding")
        }

        guard let messages = try? JSONDecoder().decode([ShortcutsMessageDTO].self, from: data) else {
            return .result(value: "Error: Could not parse messages JSON")
        }

        // Group messages by contact
        var byContact: [String: [ShortcutsMessage]] = [:]

        for dto in messages {
            guard let date = parseDate(dto.date) else { continue }
            let contact = dto.sender.trimmingCharacters(in: .whitespaces)
            guard !contact.isEmpty else { continue }

            let msg = ShortcutsMessage(
                contact: contact,
                text: dto.text ?? "",
                date: date,
                isFromMe: dto.is_from_me ?? false
            )

            // Group by the OTHER person's name (not "Me")
            if msg.isFromMe {
                // We'll associate sent messages with their conversation partner later
                byContact["__sent__", default: []].append(msg)
            } else {
                byContact[contact, default: []].append(msg)
            }
        }

        // Redistribute sent messages: match them to the nearest received message's contact
        // by looking at message timestamps
        let sentMessages = byContact.removeValue(forKey: "__sent__") ?? []
        if !sentMessages.isEmpty && !byContact.isEmpty {
            // For each sent message, find which contact's conversation it belongs to
            // by checking which contact has messages closest in time
            let allReceived = byContact.flatMap { (name, msgs) in msgs.map { (name, $0) } }
                .sorted { $0.1.date < $1.1.date }

            for sent in sentMessages {
                // Find the closest received message by time
                var bestContact = byContact.keys.first ?? "Unknown"
                var bestDistance: TimeInterval = .infinity

                for (contactName, received) in allReceived {
                    let distance = abs(sent.date.timeIntervalSince(received.date))
                    if distance < bestDistance {
                        bestDistance = distance
                        bestContact = contactName
                    }
                }

                let reassigned = ShortcutsMessage(
                    contact: bestContact,
                    text: sent.text,
                    date: sent.date,
                    isFromMe: true
                )
                byContact[bestContact, default: []].append(reassigned)
            }
        }

        // Import all contacts
        var totalImported = 0
        for (_, msgs) in byContact {
            let sorted = msgs.sorted { $0.date < $1.date }
            LiveDataStore.shared.importShortcutsData(sorted)
            totalImported += sorted.count
        }

        let contactCount = byContact.count

        // Mark shortcut as installed
        await MainActor.run {
            AutoSyncManager.shared.shortcutInstalled = true
            AutoSyncManager.shared.lastSyncDate = Date()
        }

        NotificationCenter.default.post(name: .shortcutsImportCompleted, object: totalImported)

        return .result(value: "Imported \(totalImported) messages from \(contactCount) contacts")
    }

    private func parseDate(_ string: String) -> Date? {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd HH:mm:ss",
            "MMM d, yyyy 'at' h:mm:ss a",
            "MMM d, yyyy 'at' h:mm a",
            "MM/dd/yyyy HH:mm",
            "MM/dd/yyyy h:mm a",
            "d MMM yyyy, HH:mm",
        ]
        for fmt in formats {
            let f = DateFormatter()
            f.dateFormat = fmt
            f.locale = Locale(identifier: "en_US_POSIX")
            if let date = f.date(from: string) { return date }
        }
        // Try ISO8601
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) { return date }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: string)
    }
}

private struct ShortcutsMessageDTO: Decodable {
    let sender: String
    let text: String?
    let date: String
    let is_from_me: Bool?
}

/// Simple intent to log a single message event
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
