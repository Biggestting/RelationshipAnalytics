import SwiftUI

struct CallPatternsCard: View {
    let hourlyData: [HourlyCallData]

    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 2
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let hourLabels = [0, 3, 6, 9, 12, 15, 18, 21]

    // Pre-build lookup dictionary: "day-hour" -> intensity (O(1) instead of O(n))
    private var lookup: [String: Int] {
        var dict: [String: Int] = [:]
        for d in hourlyData {
            dict["\(d.dayOfWeek)-\(d.hour)"] = d.intensity
        }
        return dict
    }

    var body: some View {
        let lut = lookup // compute once per render

        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("CALL PATTERNS")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(spacing: cellSpacing) {
                    HStack(spacing: 0) {
                        Text("")
                            .frame(width: 16)
                        ForEach(0..<24, id: \.self) { hour in
                            if hourLabels.contains(hour) {
                                Text(hourLabel(hour))
                                    .font(.system(size: 7, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .frame(width: cellSize + cellSpacing)
                            } else {
                                Color.clear
                                    .frame(width: cellSize + cellSpacing)
                            }
                        }
                    }

                    ForEach(1...7, id: \.self) { day in
                        HStack(spacing: cellSpacing) {
                            Text(dayLabels[day - 1])
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                                .frame(width: 12, alignment: .trailing)

                            ForEach(0..<24, id: \.self) { hour in
                                let intensity = lut["\(day)-\(hour)"] ?? 0
                                Rectangle()
                                    .fill(AppTheme.heatmapColors[intensity])
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }

                HStack {
                    Text("FEWER CALLS")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<5) { level in
                            Rectangle()
                                .fill(AppTheme.heatmapColors[level])
                                .frame(width: 8, height: 8)
                        }
                    }
                    Spacer()
                    Text("MORE CALLS")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12A" }
        if hour == 12 { return "12P" }
        let h = hour % 12
        return "\(h)\(hour < 12 ? "A" : "P")"
    }
}

