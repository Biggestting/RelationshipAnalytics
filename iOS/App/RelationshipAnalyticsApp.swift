import SwiftUI

@main
struct RelationshipAnalyticsApp: App {
    @StateObject private var appearanceManager = AppearanceManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appearanceManager)
                .preferredColorScheme(appearanceManager.mode.colorScheme)
        }
    }
}
