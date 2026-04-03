import SwiftUI

@main
struct RelationshipAnalyticsApp: App {
    @StateObject private var appearanceManager = AppearanceManager()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        CallTracker.shared.startTracking()
        MessageTracker.shared.startTracking()
        AutoSyncManager.shared.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appearanceManager)
                .preferredColorScheme(appearanceManager.mode.colorScheme)
                .onOpenURL { url in
                    _ = ShortcutsIntegration.shared.handleURL(url)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                AutoSyncManager.shared.syncIfNeeded()
            }
        }
    }
}
