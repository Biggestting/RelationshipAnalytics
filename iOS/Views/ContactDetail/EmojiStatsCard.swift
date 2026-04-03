import SwiftUI

struct EmojiStatsCard: View {
    let emojiStats: EmojiStats?
    let contactName: String

    var body: some View {
        if let stats = emojiStats, !stats.topEmojis.isEmpty {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("TOP EMOJIS")
                            .font(AppTheme.cardTitle)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("\(stats.totalEmojis) TOTAL · \(stats.uniqueEmojiCount) UNIQUE")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    // Top emojis with bars
                    let maxCount = stats.topEmojis.first?.count ?? 1
                    ForEach(stats.topEmojis.prefix(5)) { emoji in
                        HStack(spacing: 10) {
                            Text(emoji.emoji)
                                .font(.system(size: 22))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 3) {
                                // Stacked bar: you vs them
                                GeometryReader { geometry in
                                    let totalWidth = geometry.size.width * CGFloat(emoji.count) / CGFloat(maxCount)
                                    let youWidth = emoji.count > 0
                                        ? totalWidth * CGFloat(emoji.fromYou) / CGFloat(emoji.count) : 0

                                    HStack(spacing: 1) {
                                        if youWidth > 0 {
                                            RoundedRectangle(cornerRadius: 1)
                                                .fill(AppTheme.barFill)
                                                .frame(width: youWidth)
                                        }
                                        if totalWidth - youWidth > 0 {
                                            RoundedRectangle(cornerRadius: 1)
                                                .fill(AppTheme.barEmpty)
                                                .frame(width: totalWidth - youWidth)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                }
                                .frame(height: 6)

                                HStack(spacing: 0) {
                                    Text("\(emoji.count)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Text("  YOU \(emoji.fromYou) · \(contactName.uppercased()) \(emoji.fromThem)")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundStyle(AppTheme.textMuted)
                                }
                            }
                        }
                    }

                    // You vs them comparison
                    Rectangle()
                        .fill(AppTheme.divider)
                        .frame(height: 1)

                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                ForEach(stats.yourTopEmojis.prefix(3)) { e in
                                    Text(e.emoji).font(.system(size: 16))
                                }
                            }
                            Text("YOUR TOP 3")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(AppTheme.cardBorder)
                            .frame(width: 1, height: 40)

                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                ForEach(stats.theirTopEmojis.prefix(3)) { e in
                                    Text(e.emoji).font(.system(size: 16))
                                }
                            }
                            Text("\(contactName.uppercased())'S TOP 3")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

#Preview {
    EmojiStatsCard(emojiStats: MockDataProvider.messageStats.emojiStats, contactName: "Nina")
        .padding()
        .background(Color.black)
}
