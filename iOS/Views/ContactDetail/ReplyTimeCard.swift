import SwiftUI

struct ReplyTimeCard: View {
    let stats: MessageStats
    let contactName: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                HStack {
                    Text("Reply time")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("All time")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                // Stats row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Text(stats.yourReplyTimeFormatted)
                            .font(AppTheme.largeStat)
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(contactName)
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Text(stats.theirReplyTimeFormatted)
                            .font(AppTheme.largeStat)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }

                // Insight
                let faster = stats.theirReplyTime < stats.yourReplyTime ? contactName : "You"
                Text("\(faster) usually replies faster.")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }
}

#Preview {
    ReplyTimeCard(stats: MockDataProvider.messageStats, contactName: "Nina")
        .padding()
        .background(AppTheme.background)
}
