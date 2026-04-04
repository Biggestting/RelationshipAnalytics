import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    @StateObject private var cloudKitFetcher = CloudKitFetcher.shared

    var body: some View {
        NavigationStack {
            ContactListView(
                contacts: [],
                cloudKitBundles: cloudKitFetcher.bundles
            )
        }
        .tint(AppTheme.textPrimary)
        .task {
            await cloudKitFetcher.fetchIfNeeded()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppearanceManager())
        .preferredColorScheme(.dark)
}
