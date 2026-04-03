import AppIntents

/// Provides pre-built shortcuts that appear in the Shortcuts app automatically.
/// Users see these under "Relationship Analytics" in Shortcuts → App Shortcuts.
struct RAShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ImportMessagesIntent(),
            phrases: [
                "Import messages into \(.applicationName)",
                "Import chat history to \(.applicationName)",
                "Send messages to \(.applicationName)",
            ],
            shortTitle: "Import Messages",
            systemImageName: "bubble.left.and.bubble.right"
        )

        AppShortcut(
            intent: LogMessageIntent(),
            phrases: [
                "Log a message in \(.applicationName)",
                "Track a message with \(.applicationName)",
            ],
            shortTitle: "Log Message",
            systemImageName: "message"
        )

        AppShortcut(
            intent: LogCallIntent(),
            phrases: [
                "Log a call in \(.applicationName)",
                "Track a phone call with \(.applicationName)",
            ],
            shortTitle: "Log Call",
            systemImageName: "phone"
        )
    }
}
