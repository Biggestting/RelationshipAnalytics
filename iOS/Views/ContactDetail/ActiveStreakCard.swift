import SwiftUI

struct ActiveStreakCard: View {
    let streak: Int
    let bestStreak: Int

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Text("Active streak")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                // Circular gauge
                ZStack {
                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 4]))
                        .frame(width: 70, height: 70)

                    if bestStreak > 0 {
                        Circle()
                            .trim(from: 0, to: CGFloat(streak) / CGFloat(bestStreak))
                            .stroke(AppTheme.primaryPink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                    }

                    VStack(spacing: 0) {
                        Text("\(streak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }

                Text("days")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.streakRed)

                Text("Best \(bestStreak)")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ActiveStreakCard(streak: 0, bestStreak: 4)
        .frame(width: 170)
        .background(AppTheme.background)
}
