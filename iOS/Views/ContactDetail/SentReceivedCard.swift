import SwiftUI

struct SentReceivedCard: View {
    let stats: MessageStats

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Title row
                HStack {
                    Text("Sent vs Received")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("All time")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                // Progress bar
                GeometryReader { geometry in
                    let sentWidth = geometry.size.width * (stats.sentPercentage / 100)
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.primaryPink)
                            .frame(width: sentWidth)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.primaryPink.opacity(0.3))
                    }
                }
                .frame(height: 8)

                // Labels
                HStack {
                    Text("\(stats.totalSent) sent (\(Int(stats.sentPercentage))%)")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(stats.totalReceived) received (\(Int(stats.receivedPercentage))%)")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}

#Preview {
    SentReceivedCard(stats: MockDataProvider.messageStats)
        .padding()
        .background(AppTheme.background)
}
