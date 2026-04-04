import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager

    var body: some View {
        NavigationStack {
            ContactListView(contacts: [])
        }
        .tint(AppTheme.textPrimary)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppearanceManager())
        .preferredColorScheme(.dark)
}
