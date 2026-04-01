import SwiftUI

struct GradientBackground: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            // Ambient gradient glow at top
            EllipticalGradient(
                colors: [
                    AppTheme.primaryPink.opacity(0.3),
                    AppTheme.primaryPurple.opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadiusFraction: 0,
                endRadiusFraction: 0.7
            )
            .ignoresSafeArea()
            .offset(y: -200)
        }
    }
}

#Preview {
    GradientBackground()
}
