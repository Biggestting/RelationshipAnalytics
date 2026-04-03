import SwiftUI

enum AppTheme {
    // MARK: - Adaptive Colors (Nothing: monochrome + single red accent)

    static let background = Color("background", bundle: nil)
    static let cardBackground = Color("cardBackground", bundle: nil)
    static let cardBorder = Color("cardBorder", bundle: nil)

    static let accentRed = Color(hex: "D32F2F")

    static let textPrimary = Color("textPrimary", bundle: nil)
    static let textSecondary = Color("textSecondary", bundle: nil)
    static let textMuted = Color("textMuted", bundle: nil)

    // Fallback non-adaptive colors for contexts where color assets aren't loaded
    static let backgroundDark = Color.black
    static let backgroundLight = Color(hex: "F2F2F2")

    // MARK: - Heatmap (adapts to theme)
    static func heatmapColors(for scheme: ColorScheme) -> [Color] {
        if scheme == .light {
            return [
                Color(hex: "E8E8E8"),
                Color.black.opacity(0.12),
                Color.black.opacity(0.25),
                Color.black.opacity(0.45),
                Color.black.opacity(0.75),
            ]
        }
        return [
            Color(hex: "111111"),
            Color.white.opacity(0.15),
            Color.white.opacity(0.30),
            Color.white.opacity(0.55),
            Color.white.opacity(0.85),
        ]
    }

    // Static dark heatmap for views that don't have access to colorScheme
    static let heatmapColors: [Color] = [
        Color(hex: "111111"),
        Color.white.opacity(0.15),
        Color.white.opacity(0.30),
        Color.white.opacity(0.55),
        Color.white.opacity(0.85),
    ]

    // MARK: - Typography (monospaced, industrial)
    static let largeStat = Font.system(size: 40, weight: .bold, design: .monospaced)
    static let mediumStat = Font.system(size: 26, weight: .bold, design: .monospaced)
    static let cardTitle = Font.system(size: 13, weight: .medium, design: .monospaced)
    static let cardSubtitle = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let bodyText = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let caption = Font.system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Dimensions (sharp, industrial)
    static let cardCornerRadius: CGFloat = 6
    static let cardPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 10
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
