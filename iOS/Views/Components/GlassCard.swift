import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .fill(AppTheme.cardGlassGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}

#Preview {
    GlassCard {
        Text("Hello")
            .foregroundStyle(.white)
    }
    .padding()
    .background(AppTheme.background)
}
