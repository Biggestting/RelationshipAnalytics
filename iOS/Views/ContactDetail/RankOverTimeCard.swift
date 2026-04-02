import SwiftUI
import Charts

struct RankOverTimeCard: View {
    let rankData: RankData

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("RANK OVER TIME")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("LAST 12 MONTHS")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                Chart(rankData.rankHistory) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Rank", point.rank)
                    )
                    .foregroundStyle(Color.white)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Rank", point.rank)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
                .chartYScale(domain: 1...31)
                .chartYAxis {
                    AxisMarks(values: [1, 16, 31]) { value in
                        AxisValueLabel {
                            if let rank = value.as(Int.self) {
                                Text("#\(rank)")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.05))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(AppTheme.textMuted)
                            .font(.system(size: 8, design: .monospaced))
                    }
                }
                .frame(height: 120)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CURRENT")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Text(rankData.currentRankFormatted)
                            .font(AppTheme.mediumStat)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(rankData.currentDateFormatted.uppercased())
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BEST")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Text(rankData.bestRankFormatted)
                            .font(AppTheme.mediumStat)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(rankData.bestDateFormatted.uppercased())
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }
        }
    }
}

#Preview {
    RankOverTimeCard(rankData: MockDataProvider.rankData)
        .padding()
        .background(Color.black)
}
