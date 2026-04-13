import SwiftUI

struct FirstMessagesCard: View {
    let firstMessage: MessagePreview?

    var body: some View {
        if let message = firstMessage {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("FIRST MESSAGES")
                            .font(AppTheme.cardTitle)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("JUMP")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }

                    HStack {
                        if message.isFromUser { Spacer() }

                        Text(message.text)
                            .font(AppTheme.bodyText)
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                    .fill(AppTheme.bubbleBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                    )
                            )

                        if !message.isFromUser { Spacer() }
                    }
                }
            }
        }
    }
}

