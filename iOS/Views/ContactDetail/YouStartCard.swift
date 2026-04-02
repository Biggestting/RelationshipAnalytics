import SwiftUI

struct YouStartCard: View {
    let percentage: Double

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Text("YOU START")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("\(Int(percentage))%")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("OF CONVERSATIONS")
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
        .background(Color.black)
}
