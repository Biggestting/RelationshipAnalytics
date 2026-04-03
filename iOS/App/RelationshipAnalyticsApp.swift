import SwiftUI

@main
struct RelationshipAnalyticsApp: App {
    @StateObject private var appearanceManager = AppearanceManager()

    init() {
        // Start live tracking on launch
        CallTracker.shared.startTracking()
        MessageTracker.shared.startTracking()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appearanceManager)
                .preferredColorScheme(appearanceManager.mode.colorScheme)
                .onOpenURL { url in
                    // Handle ra://import?data=... from Shortcuts
                    _ = ShortcutsIntegration.shared.handleURL(url)
                }
        }
    }
}
