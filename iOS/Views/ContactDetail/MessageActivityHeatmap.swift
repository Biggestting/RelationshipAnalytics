import SwiftUI

struct MessageActivityHeatmap: View {
    let stats: MessageStats

    private let columns = 26  // ~6 months of weeks
    private let rows = 7      // days of week
    private let cellSize: CGFloat = 8
    private let cellSpacing: CGFloat = 3

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                HStack {
                    Text("Message activity")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Since Sep '25")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                // Heatmap grid
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: rows), spacing: cellSpacing) {
                        ForEach(Array(stats.messageActivity.enumerated()), id: \.offset) { _, activity in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.heatmapColors[activity.intensity])
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
                .frame(height: CGFloat(rows) * (cellSize + cellSpacing))

                // Footer
                HStack {
                    Text("\(stats.totalMessages) messages")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer()

                    // Legend
                    HStack(spacing: 4) {
                        Text("Less")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textMuted)

                        ForEach(0..<5) { level in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.heatmapColors[level])
                                .frame(width: 8, height: 8)
                        }

                        Text("More")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }
        }
    }
}

#Preview {
    MessageActivityHeatmap(stats: MockDataProvider.messageStats)
        .padding()
        .background(AppTheme.background)
}
