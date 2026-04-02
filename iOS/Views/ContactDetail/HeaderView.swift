import SwiftUI

struct HeaderView: View {
    let contact: ContactProfile

    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "1A1A1A"))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )

                Text(contact.initials)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            // Name
            Text(contact.name.uppercased())
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)

            // Talking since
            Text(contact.talkingSinceFormatted.uppercased())
                .font(AppTheme.cardSubtitle)
                .foregroundStyle(AppTheme.textSecondary)

            // Duration badge
            Text(contact.talkingDuration.uppercased())
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

#Preview {
    HeaderView(contact: MockDataProvider.contact)
        .background(Color.black)
}
