import SwiftUI

struct ActiveStreakCard: View {
    let streak: Int
    let bestStreak: Int

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Text("ACTIVE STREAK")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                ZStack {
                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(AppTheme.gaugeTrack, style: StrokeStyle(lineWidth: 3, lineCap: .butt, dash: [2, 4]))
                        .frame(width: 66, height: 66)

                    if bestStreak > 0 {
                        Circle()
                            .trim(from: 0, to: CGFloat(streak) / CGFloat(bestStreak))
                            .stroke(AppTheme.accentRed, style: StrokeStyle(lineWidth: 3, lineCap: .butt))
                            .frame(width: 66, height: 66)
                            .rotationEffect(.degrees(-90))
                    }

                    Text("\(streak)")
                        .font(AppTheme.mediumStat)
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Text("DAYS")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.accentRed)

                Text("BEST \(bestStreak)")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

