import SwiftUI

enum AppTheme {
    // MARK: - Adaptive Colors (Nothing: monochrome + single red accent)
    // Uses UIColor/NSColor for reliable dark/light switching

    #if canImport(UIKit)
    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.black : UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1)
    })

    static let cardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1) : UIColor.white
    })

    static let cardBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.10) : UIColor.black.withAlphaComponent(0.10)
    })

    static let textPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.white : UIColor(red: 0.067, green: 0.067, blue: 0.067, alpha: 1)
    })

    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.541, alpha: 1) : UIColor(white: 0.400, alpha: 1)
    })

    static let textMuted = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.333, alpha: 1) : UIColor(white: 0.600, alpha: 1)
    })
    #else
    // macOS fallback — always dark
    static let background = Color.black
    static let cardBackground = Color(hex: "0A0A0A")
    static let cardBorder = Color.white.opacity(0.10)
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8A8A8A")
    static let textMuted = Color(hex: "555555")
    #endif

    static let accentRed = Color(hex: "D32F2F")

    // MARK: - Adaptive UI element colors

    #if canImport(UIKit)
    /// Dividers and separators
    static let divider = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.06) : UIColor.black.withAlphaComponent(0.08)
    })

    /// Progress bars, chart bars — strong foreground
    static let barFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.7) : UIColor.black.withAlphaComponent(0.7)
    })

    /// Progress bars — inactive/empty portion
    static let barEmpty = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.15) : UIColor.black.withAlphaComponent(0.12)
    })

    /// Chart grid lines
    static let gridLine = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.05) : UIColor.black.withAlphaComponent(0.06)
    })

    /// Chart area fill gradient start
    static let chartAreaFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.12) : UIColor.black.withAlphaComponent(0.08)
    })

    /// Gauge/streak circle background
    static let gaugeTrack = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.08) : UIColor.black.withAlphaComponent(0.08)
    })

    /// Message bubble background
    static let bubbleBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.1, alpha: 1) : UIColor(white: 0.92, alpha: 1)
    })
    #else
    static let divider = Color.white.opacity(0.06)
    static let barFill = Color.white.opacity(0.7)
    static let barEmpty = Color.white.opacity(0.15)
    static let gridLine = Color.white.opacity(0.05)
    static let chartAreaFill = Color.white.opacity(0.12)
    static let gaugeTrack = Color.white.opacity(0.08)
    static let bubbleBackground = Color(hex: "1A1A1A")
    #endif

    // MARK: - Heatmap
    #if canImport(UIKit)
    static let heatmapColors: [Color] = [
        Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(white: 0.067, alpha: 1) : UIColor(white: 0.91, alpha: 1) }),
        Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.15) : UIColor.black.withAlphaComponent(0.10) }),
        Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.30) : UIColor.black.withAlphaComponent(0.22) }),
        Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.55) : UIColor.black.withAlphaComponent(0.40) }),
        Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.85) : UIColor.black.withAlphaComponent(0.65) }),
    ]
    #else
    static let heatmapColors: [Color] = [
        Color(hex: "111111"),
        Color.white.opacity(0.15),
        Color.white.opacity(0.30),
        Color.white.opacity(0.55),
        Color.white.opacity(0.85),
    ]
    #endif

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
