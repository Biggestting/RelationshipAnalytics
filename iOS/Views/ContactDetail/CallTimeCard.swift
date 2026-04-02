import SwiftUI
import Charts

struct CallTimeCard: View {
    let callStats: CallStats

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CALL TIME")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("LAST 12 MONTHS")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                Chart(callStats.monthlyCallData) { data in
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Minutes", data.totalMinutes)
                    )
                    .foregroundStyle(Color.white.opacity(0.7))
                    .cornerRadius(1)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.textMuted)
                            .font(.system(size: 8, design: .monospaced))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.05))
                    }
                }
                .frame(height: 80)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(callStats.totalCallTimeFormatted)
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("TOTAL")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        Text("\(callStats.answeredCalls) ANSWERED CALLS")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(callStats.averageCallFormatted)
                                .font(AppTheme.mediumStat)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("AVG")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        if let lastAnswered = callStats.lastAnsweredFormatted {
                            Text(lastAnswered.uppercased())
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
        .background(Color.black)
}
