import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    @StateObject private var cloudKitFetcher = CloudKitFetcher.shared
    @State private var macExportBundles: [ContactAnalyticsBundle] = []

    var body: some View {
        NavigationStack {
            ContactListView(
                contacts: [],
                cloudKitBundles: cloudKitFetcher.bundles + macExportBundles
            )
        }
        .tint(AppTheme.textPrimary)
        .task {
            await cloudKitFetcher.fetchIfNeeded()
            macExportBundles = MacExportImporter.shared.loadCachedBundles()
        }
        .onOpenURL { url in
            if url.scheme == "ra" || url.scheme == "relationshipanalytics" {
                _ = ShortcutsIntegration.shared.handleURL(url)
                return
            }
            if url.pathExtension == "json" {
                if let bundles = try? MacExportImporter.shared.importFile(from: url) {
                    macExportBundles = bundles
                }
            }
        }
    }
}

