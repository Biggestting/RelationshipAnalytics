import SwiftUI

struct LongestConvoCard: View {
    let convo: ConversationInfo?

    var body: some View {
        if let convo {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("LONGEST CONVO")
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

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MESSAGES")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Text("\(convo.messageCount)")
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("LENGTH")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Text(convo.durationFormatted)
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }

                    Text(convo.dateRangeFormatted.uppercased())
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
    }
}

