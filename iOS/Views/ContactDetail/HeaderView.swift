import SwiftUI

struct HeaderView: View {
    let contact: ContactProfile

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                Text(contact.initials)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Text(contact.name.uppercased())
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)

            Text(contact.talkingSinceFormatted.uppercased())
                .font(AppTheme.cardSubtitle)
                .foregroundStyle(AppTheme.textSecondary)

            Text(contact.talkingDuration.uppercased())
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
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
