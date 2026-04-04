import Foundation
import Intents

/// Provides URL scheme and App Intent-based integration with iOS Shortcuts.
///
/// Users build a Shortcut that:
/// 1. Uses "Find Messages" action to get messages from a contact
/// 2. Repeats through results, building a JSON array
/// 3. Passes the JSON to our app via URL scheme or App Intent
///
/// The Shortcut template is provided in-app with a "Get Shortcut" button
/// that opens the Shortcuts app with a pre-built workflow.
final class ShortcutsIntegration {
    static let shared = ShortcutsIntegration()
    private let store = LiveDataStore.shared

    private init() {}

    // MARK: - Handle incoming URL

    /// Handle ra://import?data=<base64 JSON>
    func handleURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "ra" || components.scheme == "relationshipanalytics",
              components.host == "import" else {
            return false
        }

        guard let dataParam = components.queryItems?.first(where: { $0.name == "data" })?.value,
              let decoded = Data(base64Encoded: dataParam) else {
            return false
        }

        return processImportData(decoded)
    }

    /// Handle shared JSON file from Shortcuts "Share" action
    func handleSharedFile(_ url: URL) -> Bool {
        guard url.pathExtension == "json",
              let data = try? Data(contentsOf: url) else {
            return false
        }
        return processImportData(data)
    }

    // MARK: - Process Import

    private func processImportData(_ data: Data) -> Bool {
        do {
            let messages = try JSONDecoder().decode([ShortcutsMessageDTO].self, from: data)
            let converted = messages.compactMap { dto -> ShortcutsMessage? in
                guard let date = parseDate(dto.date) else { return nil }
                return ShortcutsMessage(
                    contact: dto.sender,
                    text: dto.text ?? "",
                    date: date,
                    isFromMe: dto.is_from_me ?? false
                )
            }

            guard !converted.isEmpty else { return false }
            store.importShortcutsData(converted)

            NotificationCenter.default.post(name: .shortcutsImportCompleted, object: converted.count)
            return true
        } catch {
            return false
        }
    }

    private func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = {
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd HH:mm:ss",
                "MMM d, yyyy 'at' h:mm a",
                "MM/dd/yyyy HH:mm",
            ]
            return formats.map { fmt in
                let f = DateFormatter()
                f.dateFormat = fmt
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }
        }()

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    // MARK: - Shortcut Template

    /// Returns the Shortcuts URL that creates a pre-built import workflow
    var shortcutInstallURL: URL? {
        // This would link to a shared iCloud Shortcut
        // For now, return the Shortcuts app URL
        URL(string: "shortcuts://")
    }

    /// Instructions for building the Shortcut manually
    static let shortcutInstructions = """
    BUILD THIS SHORTCUT IN THE SHORTCUTS APP:

    1. ADD ACTION: "FIND MESSAGES"
       - NO FILTER (GETS ALL CONTACTS AT ONCE)
       - SORT BY: DATE SENT (OLDEST FIRST)

    2. ADD ACTION: "REPEAT WITH EACH" (MESSAGES)

    3. INSIDE REPEAT:
       ADD ACTION: "TEXT"
       {"sender":"[SENDER]","text":"[TEXT]","date":"[DATE SENT]","is_from_me":[IS FROM ME]}

    4. AFTER REPEAT:
       ADD ACTION: "COMBINE TEXT" (COMMA)

    5. ADD ACTION: "TEXT"
       [[COMBINED TEXT]]

    6. ADD ACTION: "IMPORT MESSAGES"
       (FROM RELATIONSHIP ANALYTICS)
       SET MESSAGES JSON TO THE TEXT ABOVE

    NO NEED TO SELECT INDIVIDUAL CONTACTS —
    ALL CONVERSATIONS ARE IMPORTED AT ONCE.
    """
}

extension Notification.Name {
    static let shortcutsImportCompleted = Notification.Name("shortcutsImportCompleted")
}

// DTO for parsing Shortcuts JSON
private struct ShortcutsMessageDTO: Decodable {
    let sender: String
    let text: String?
    let date: String
    let is_from_me: Bool?
}
