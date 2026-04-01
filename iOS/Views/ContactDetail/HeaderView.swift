import SwiftUI

struct HeaderView: View {
    let contact: ContactProfile

    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "374151"))
                    .frame(width: 64, height: 64)

                Text(contact.initials)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            // Name
            Text(contact.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            // Talking since
            Text(contact.talkingSinceFormatted)
                .font(AppTheme.cardSubtitle)
                .foregroundStyle(AppTheme.textSecondary)

            // Duration badge
            Text(contact.talkingDuration)
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

#Preview {
    HeaderView(contact: MockDataProvider.contact)
        .background(AppTheme.background)
}
