import SwiftUI

struct MissedCallsCard: View {
    let stats: MissedCallStats
    let contactName: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("MISSED VS ANSWERED")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(spacing: 10) {
                    AnswerRateRow(label: "YOU", rate: stats.yourAnswerRate, missed: stats.youMissed)
                    AnswerRateRow(label: contactName.uppercased(), rate: stats.theirAnswerRate, missed: stats.theyMissed)
                }

                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 1)

                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("\(stats.totalAnswered)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("ANSWERED")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(AppTheme.cardBorder)
                        .frame(width: 1, height: 36)

                    VStack(spacing: 4) {
                        Text("\(stats.totalMissed)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.accentRed)
                        Text("MISSED")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(AppTheme.cardBorder)
                        .frame(width: 1, height: 36)

                    VStack(spacing: 4) {
                        Text("\(stats.longestUnansweredStreak)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("STREAK")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct AnswerRateRow: View {
    let label: String
    let rate: Double
    let missed: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
                Text("\(Int(rate))% ANSWER RATE")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            GeometryReader { geometry in
                let answeredWidth = geometry.size.width * (rate / 100)
                HStack(spacing: 1) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(AppTheme.barFill)
                        .frame(width: answeredWidth)

                    if rate < 100 {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(AppTheme.accentRed.opacity(0.5))
                    }
                }
            }
            .frame(height: 4)
        }
    }
}

