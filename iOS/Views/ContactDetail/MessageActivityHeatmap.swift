import SwiftUI

struct MessageActivityHeatmap: View {
    let stats: MessageStats
    let contactName: String

    private let rows = 7
    private let cellSize: CGFloat = 7
    private let cellSpacing: CGFloat = 3

    var body: some View {
        NavigationLink {
            MessageActivityDetailView(stats: stats, contactName: contactName)
        } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("MESSAGE ACTIVITY")
                            .font(AppTheme.cardTitle)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("DETAILS")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: rows), spacing: cellSpacing) {
                            ForEach(Array(stats.messageActivity.enumerated()), id: \.offset) { _, activity in
                                Rectangle()
                                    .fill(AppTheme.heatmapColors[activity.intensity])
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                    .frame(height: CGFloat(rows) * (cellSize + cellSpacing))

                    HStack {
                        Text("\(stats.totalMessages) MESSAGES")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textSecondary)

                        Spacer()

                        HStack(spacing: 3) {
                            Text("LESS")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)

                            ForEach(0..<5) { level in
                                Rectangle()
                                    .fill(AppTheme.heatmapColors[level])
                                    .frame(width: 7, height: 7)
                            }

                            Text("MORE")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MessageActivityHeatmap(stats: MockDataProvider.messageStats, contactName: "Nina")
            .padding()
            .background(AppTheme.background)
    }
}
