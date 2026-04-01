import SwiftUI
import Charts

struct CallTimeCard: View {
    let callStats: CallStats

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                HStack {
                    Text("Call time")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("Last 12 months")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                // Bar chart
                Chart(callStats.monthlyCallData) { data in
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Minutes", data.totalMinutes)
                    )
                    .foregroundStyle(AppTheme.primaryPink)
                    .cornerRadius(2)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.textMuted)
                            .font(.system(size: 9))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.05))
                    }
                }
                .frame(height: 80)

                // Stats row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(callStats.totalCallTimeFormatted)
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("total")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        Text("\(callStats.answeredCalls) answered calls")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(callStats.averageCallFormatted)
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("avg")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        if let lastAnswered = callStats.lastAnsweredFormatted {
                            Text(lastAnswered)
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CallTimeCard(callStats: MockDataProvider.callStats)
        .padding()
        .background(AppTheme.background)
}
