import SwiftUI

struct SentReceivedCard: View {
    let stats: MessageStats

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("SENT VS RECEIVED")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("ALL TIME")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                GeometryReader { geometry in
                    let sentWidth = geometry.size.width * (stats.sentPercentage / 100)
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppTheme.barFill)
                            .frame(width: sentWidth)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppTheme.barEmpty)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(stats.totalSent) SENT (\(Int(stats.sentPercentage))%)")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(stats.totalReceived) RECEIVED (\(Int(stats.receivedPercentage))%)")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}

