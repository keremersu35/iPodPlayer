import SwiftUI

enum ThemeType: String, CaseIterable {
    case silver, dark, u2Edition

    var caseAppearance: String {
        switch self {
        case .silver: return ImageNames.Custom.lightTheme
        case .dark, .u2Edition: return ImageNames.Custom.darkTheme
        }
    }

    var wheelIconTint: Color {
        switch self {
        case .silver: return .buttonIconTint
        case .dark, .u2Edition: return .white
        }
    }

    var wheelColor: Color {
        switch self {
        case .silver: return .wheelSilver
        case .dark: return .wheelDark
        case .u2Edition: return .wheelU2
        }
    }

    var wheelInnerAppearance: String {
        switch self {
        case .silver: return ImageNames.Custom.lightThemeButton
        case .dark, .u2Edition: return ImageNames.Custom.darkThemeButton
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var currentTheme: ThemeType

    init() {
        let saved = UserDefaults.standard.string(forKey: UserDefaultsKeys.currentTheme.rawValue).flatMap(ThemeType.init)
        currentTheme = saved ?? .silver
    }

    func setTheme(_ themeType: ThemeType) {
        currentTheme = themeType
        UserDefaults.standard.set(themeType.rawValue, forKey: UserDefaultsKeys.currentTheme.rawValue)
    }
}
