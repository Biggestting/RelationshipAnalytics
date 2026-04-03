import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "SYSTEM"
    case dark = "DARK"
    case light = "LIGHT"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

@MainActor
final class AppearanceManager: ObservableObject {
    @Published var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appearanceMode") ?? "DARK"
        self.mode = AppearanceMode(rawValue: saved) ?? .dark
    }
}
