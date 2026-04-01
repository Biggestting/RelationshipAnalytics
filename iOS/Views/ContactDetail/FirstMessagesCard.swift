import SwiftUI

struct FirstMessagesCard: View {
    let firstMessage: MessagePreview?

    var body: some View {
        if let message = firstMessage {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("First messages")
                            .font(AppTheme.cardTitle)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Jump")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }

                    // Message bubble
                    HStack {
                        if message.isFromUser { Spacer() }

                        Text(message.text)
                            .font(AppTheme.bodyText)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(message.isFromUser ? AppTheme.primaryPink : Color(hex: "374151"))
                            )

                        if !message.isFromUser { Spacer() }
                    }
                }
            }
        }
    }
}

#Preview {
    FirstMessagesCard(firstMessage: MockDataProvider.messageStats.firstMessageSent)
        .padding()
        .background(AppTheme.background)
}
