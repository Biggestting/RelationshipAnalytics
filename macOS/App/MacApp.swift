import SwiftUI

@main
struct RelationshipAnalyticsMacApp: App {
    @StateObject private var syncManager = SyncManager()

    var body: some Scene {
        WindowGroup {
            MacContentView()
                .environmentObject(syncManager)
                .preferredColorScheme(.dark)
                .frame(minWidth: 500, minHeight: 600)
        }
        .windowStyle(.titleBar)

        MenuBarExtra("Relationship Analytics", systemImage: "heart.text.square") {
            Button("Sync Now") {
                Task { await syncManager.syncAll() }
            }
            Divider()
            Text("Last sync: \(syncManager.lastSyncFormatted)")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
