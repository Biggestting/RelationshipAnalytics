import SwiftUI
import Charts

struct MessageActivityDetailView: View {
    let stats: MessageStats
    let contactName: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: DayActivity?

    private var sortedActivity: [DayActivity] {
        stats.messageActivity.sorted { $0.date < $1.date }
    }

    private var busiestDay: DayActivity? {
        stats.messageActivity.max(by: { $0.count < $1.count })
    }

    private var quietestDay: DayActivity? {
        stats.messageActivity.filter { $0.count > 0 }.min(by: { $0.count < $1.count })
    }

    private var averagePerDay: Double {
        let activeDays = stats.messageActivity.filter { $0.count > 0 }
        guard !activeDays.isEmpty else { return 0 }
        return Double(activeDays.reduce(0) { $0 + $1.count }) / Double(activeDays.count)
    }

    private var activeDayCount: Int {
        stats.messageActivity.filter { $0.count > 0 }.count
    }

    private var hourlyData: [HourlyMessageData] {
        // Build hourly distribution from message activity timestamps
        // Since we only have daily data, simulate with day-of-week breakdown
        buildHourlyEstimate()
    }

    private var dayOfWeekData: [DayOfWeekData] {
        buildDayOfWeekBreakdown()
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.sectionSpacing) {

                    // MARK: - Summary Stats
                    summaryStatsSection

                    // MARK: - Full Heatmap
                    fullHeatmapSection

                    // MARK: - Selected Day Detail
                    if let selected = selectedDay {
                        selectedDayCard(selected)
                    }

                    // MARK: - Day of Week Breakdown
                    dayOfWeekSection

                    // MARK: - Daily Message Chart
                    dailyChartSection

                    // MARK: - Busiest & Quietest
                    busiestQuietestSection

                    // MARK: - Daily Breakdown List
                    dailyBreakdownList

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("MESSAGE ACTIVITY")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Summary Stats

    private var summaryStatsSection: some View {
        GlassCard {
            HStack(spacing: 0) {
                StatColumn(value: "\(stats.totalMessages)", label: "TOTAL")
                verticalDivider
                StatColumn(value: String(format: "%.1f", averagePerDay), label: "AVG/DAY")
                verticalDivider
                StatColumn(value: "\(activeDayCount)", label: "ACTIVE DAYS")
            }
        }
    }

    // MARK: - Full Heatmap

    private var fullHeatmapSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("ACTIVITY HEATMAP")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                let rows = 7
                let cellSize: CGFloat = 10
                let cellSpacing: CGFloat = 3

                // Day labels
                HStack(spacing: 0) {
                    VStack(alignment: .trailing, spacing: cellSpacing) {
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                                .frame(height: cellSize)
                        }
                    }
                    .frame(width: 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: rows), spacing: cellSpacing) {
                            ForEach(Array(sortedActivity.enumerated()), id: \.offset) { _, activity in
                                Rectangle()
                                    .fill(AppTheme.heatmapColors[activity.intensity])
                                    .frame(width: cellSize, height: cellSize)
                                    .onTapGesture {
                                        selectedDay = activity
                                    }
                                    .overlay(
                                        selectedDay?.date == activity.date ?
                                        Rectangle().strokeBorder(AppTheme.accentRed, lineWidth: 1.5) : nil
                                    )
                            }
                        }
                    }
                    .frame(height: CGFloat(rows) * (cellSize + cellSpacing))
                }

                // Legend
                HStack {
                    Text("TAP A CELL FOR DETAILS")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                    Spacer()
                    HStack(spacing: 2) {
                        Text("LESS")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                        ForEach(0..<5) { level in
                            Rectangle()
                                .fill(AppTheme.heatmapColors[level])
                                .frame(width: 8, height: 8)
                        }
                        Text("MORE")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }
        }
    }

    // MARK: - Selected Day

    private func selectedDayCard(_ day: DayActivity) -> some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayFormatted(day.date))
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(dayOfWeekFormatted(day.date))
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(day.count)")
                        .font(AppTheme.mediumStat)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("MESSAGES")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
    }

    // MARK: - Day of Week Breakdown

    private var dayOfWeekSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("BY DAY OF WEEK")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                Chart(dayOfWeekData) { data in
                    BarMark(
                        x: .value("Day", data.label),
                        y: .value("Messages", data.averageCount)
                    )
                    .foregroundStyle(AppTheme.barFill)
                    .cornerRadius(2)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.textMuted)
                            .font(.system(size: 9, design: .monospaced))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(AppTheme.gridLine)
                    }
                }
                .frame(height: 100)

                let busiest = dayOfWeekData.max(by: { $0.averageCount < $1.averageCount })
                if let busiest {
                    Text("BUSIEST: \(busiest.label.uppercased()) (\(String(format: "%.1f", busiest.averageCount)) AVG)")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
    }

    // MARK: - Daily Chart

    private var dailyChartSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("DAILY MESSAGES")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                let recent = Array(sortedActivity.suffix(30))
                Chart(recent) { data in
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(AppTheme.barFill)
                    .cornerRadius(1)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(AppTheme.textMuted)
                            .font(.system(size: 8, design: .monospaced))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(AppTheme.gridLine)
                    }
                }
                .frame(height: 100)

                Text("LAST 30 DAYS")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }

    // MARK: - Busiest & Quietest

    private var busiestQuietestSection: some View {
        HStack(spacing: AppTheme.sectionSpacing) {
            GlassCard {
                VStack(spacing: 6) {
                    Text("BUSIEST DAY")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                    if let day = busiestDay {
                        Text("\(day.count)")
                            .font(AppTheme.mediumStat)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("MESSAGES")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                        Text(dayFormatted(day.date))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            GlassCard {
                VStack(spacing: 6) {
                    Text("QUIETEST DAY")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                    if let day = quietestDay {
                        Text("\(day.count)")
                            .font(AppTheme.mediumStat)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("MESSAGES")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                        Text(dayFormatted(day.date))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Daily Breakdown List

    private var dailyBreakdownList: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT DAYS")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                let recent = sortedActivity.suffix(14).reversed()
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, day in
                    if index > 0 {
                        Rectangle()
                            .fill(AppTheme.divider)
                            .frame(height: 1)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dayFormatted(day.date))
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(dayOfWeekFormatted(day.date))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                        }

                        Spacer()

                        // Mini bar
                        let maxCount = Double(busiestDay?.count ?? 1)
                        let barWidth = max(4, CGFloat(Double(day.count) / maxCount) * 60)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(AppTheme.barFill)
                            .frame(width: barWidth, height: 6)

                        Text("\(day.count)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var verticalDivider: some View {
        Rectangle()
            .fill(AppTheme.cardBorder)
            .frame(width: 1, height: 40)
    }

    private func dayFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date).uppercased()
    }

    private func dayOfWeekFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).uppercased()
    }

    private func buildDayOfWeekBreakdown() -> [DayOfWeekData] {
        let calendar = Calendar.current
        let labels = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        var totals = [Int](repeating: 0, count: 7)
        var counts = [Int](repeating: 0, count: 7)

        for day in stats.messageActivity {
            let weekday = calendar.component(.weekday, from: day.date) - 1 // 0=Sun
            totals[weekday] += day.count
            if day.count > 0 { counts[weekday] += 1 }
        }

        return (0..<7).map { i in
            let avg = counts[i] > 0 ? Double(totals[i]) / Double(counts[i]) : 0
            return DayOfWeekData(dayIndex: i, label: labels[i], totalCount: totals[i], averageCount: avg)
        }
    }

    private func buildHourlyEstimate() -> [HourlyMessageData] {
        // We only have daily data, so return empty for now
        // This would be populated from actual message timestamps
        (0..<24).map { HourlyMessageData(hour: $0, count: 0) }
    }
}

struct StatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DayOfWeekData: Identifiable {
    var id: Int { dayIndex }
    let dayIndex: Int
    let label: String
    let totalCount: Int
    let averageCount: Double
}

struct HourlyMessageData: Identifiable {
    var id: Int { hour }
    let hour: Int
    let count: Int

}

