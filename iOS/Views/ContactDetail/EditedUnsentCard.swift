import SwiftUI

struct EditedUnsentCard: View {
    let stats: MessageStats

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("EDITED & UNSENT")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 0) {
                    // Edited
                    VStack(spacing: 6) {
                        Text("EDITED")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)

                        Text("\(stats.messagesEdited)")
                            .font(AppTheme.mediumStat)
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("\(String(format: "%.1f", stats.editedPercentage))%")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: 60)

                    // Unsent
                    VStack(spacing: 6) {
                        Text("UNSENT")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)

                        Text("\(stats.messagesUnsent)")
                            .font(AppTheme.mediumStat)
                            .foregroundStyle(AppTheme.accentRed)

                        Text("\(String(format: "%.1f", stats.unsentPercentage))%")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                Text("OF \(stats.totalMessages) TOTAL MESSAGES")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

#Preview {
    EditedUnsentCard(stats: MockDataProvider.messageStats)
        .padding()
        .background(Color.black)
}
