import SwiftUI

struct ContactListView: View {
    let contacts: [ContactProfile]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(contacts) { contact in
                        NavigationLink {
                            ContactDetailView(
                                contact: contact,
                                messageStats: MockDataProvider.messageStats,
                                callStats: MockDataProvider.callStats,
                                rankData: MockDataProvider.rankData
                            )
                        } label: {
                            ContactRow(contact: contact)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct ContactRow: View {
    let contact: ContactProfile

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryPink.opacity(0.6), AppTheme.primaryPurple.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Text(contact.initials)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(contact.talkingSinceFormatted)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground)
        )
    }
}

#Preview {
    NavigationStack {
        ContactListView(contacts: MockDataProvider.contacts)
    }
    .preferredColorScheme(.dark)
}
