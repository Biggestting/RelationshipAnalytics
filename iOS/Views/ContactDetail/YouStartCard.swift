import SwiftUI

struct YouStartCard: View {
    let percentage: Double

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Text("You start")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("\(Int(percentage))%")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryPink)

                Text("of conversations")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    YouStartCard(percentage: 74)
        .frame(width: 170)
        .background(AppTheme.background)
}
