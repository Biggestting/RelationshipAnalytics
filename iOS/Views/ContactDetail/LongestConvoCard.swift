import SwiftUI

struct LongestConvoCard: View {
    let convo: ConversationInfo?

    var body: some View {
        if let convo {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Longest convo")
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

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Messages")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Text("\(convo.messageCount)")
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Length")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Text(convo.durationFormatted)
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }

                    Text(convo.dateRangeFormatted)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
    }
}

#Preview {
    LongestConvoCard(convo: MockDataProvider.messageStats.longestConvo)
        .padding()
        .background(AppTheme.background)
}
