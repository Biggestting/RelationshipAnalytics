import SwiftUI

struct ContactListView: View {
    let contacts: [ContactProfile]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
        .navigationTitle("CONTACTS")
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
                    .fill(Color(hex: "1A1A1A"))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )

                Text(contact.initials)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name.uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(contact.talkingSinceFormatted.uppercased())
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        ContactListView(contacts: MockDataProvider.contacts)
    }
    .preferredColorScheme(.dark)
}
