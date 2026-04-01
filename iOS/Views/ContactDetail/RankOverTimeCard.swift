import SwiftUI
import Charts

struct RankOverTimeCard: View {
    let rankData: RankData

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                HStack {
                    Text("Rank over time")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("Last 12 months")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                // Line chart (inverted Y axis — rank 1 is at top)
                Chart(rankData.rankHistory) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Rank", point.rank)
                    )
                    .foregroundStyle(AppTheme.primaryPink)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Rank", point.rank)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.primaryPink.opacity(0.3), Color.clear],
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
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.05))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(AppTheme.textMuted)
                            .font(.system(size: 9))
                    }
                }
                .frame(height: 120)

                // Stats row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Text(rankData.currentRankFormatted)
                            .font(AppTheme.mediumStat)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(rankData.currentDateFormatted)
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Best")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Text(rankData.bestRankFormatted)
                            .font(AppTheme.mediumStat)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(rankData.bestDateFormatted)
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
        .background(AppTheme.background)
}
