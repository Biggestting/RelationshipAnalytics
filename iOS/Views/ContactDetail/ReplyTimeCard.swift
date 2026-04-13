import SwiftUI

struct ReplyTimeCard: View {
    let stats: MessageStats
    let contactName: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("REPLY TIME")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("ALL TIME")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOU")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Text(stats.yourReplyTimeFormatted)
                            .font(AppTheme.largeStat)
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(contactName.uppercased())
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Text(stats.theirReplyTimeFormatted)
                            .font(AppTheme.largeStat)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }

                let faster = stats.theirReplyTime < stats.yourReplyTime ? contactName : "You"
                Text("\(faster) usually replies faster.".uppercased())
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }
}

