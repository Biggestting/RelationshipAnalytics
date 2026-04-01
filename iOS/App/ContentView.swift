import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ContactListView(contacts: MockDataProvider.contacts)
        }
        .tint(.white)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
