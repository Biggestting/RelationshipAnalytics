import SwiftUI

enum AppTheme {
    // MARK: - Colors
    static let background = Color(hex: "0D0D0D")
    static let cardBackground = Color(hex: "1A1A2E").opacity(0.6)
    static let cardBorder = Color.white.opacity(0.08)

    static let primaryPink = Color(hex: "FF2D78")
    static let primaryPurple = Color(hex: "8B5CF6")
    static let primaryBlue = Color(hex: "3B82F6")

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9CA3AF")
    static let textMuted = Color(hex: "6B7280")

    static let streakRed = Color(hex: "EF4444")
    static let successGreen = Color(hex: "22C55E")

    // MARK: - Gradients
    static let headerGradient = LinearGradient(
        colors: [
            Color(hex: "FF2D78").opacity(0.8),
            Color(hex: "8B5CF6").opacity(0.6),
            Color(hex: "3B82F6").opacity(0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGlassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pinkBarGradient = LinearGradient(
        colors: [Color(hex: "FF2D78"), Color(hex: "FF6B9D")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Heatmap intensity colors
    static let heatmapColors: [Color] = [
        Color(hex: "1A1A2E"),       // 0 - empty
        Color(hex: "FF2D78").opacity(0.3),  // 1 - low
        Color(hex: "FF2D78").opacity(0.5),  // 2 - medium
        Color(hex: "FF2D78").opacity(0.75), // 3 - high
        Color(hex: "FF2D78"),               // 4 - max
    ]

    // MARK: - Typography
    static let largeStat = Font.system(size: 42, weight: .bold, design: .rounded)
    static let mediumStat = Font.system(size: 28, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 15, weight: .semibold)
    static let cardSubtitle = Font.system(size: 13, weight: .regular)
    static let bodyText = Font.system(size: 14, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let monoStat = Font.system(size: 28, weight: .bold, design: .monospaced)

    // MARK: - Dimensions
    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 12
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
