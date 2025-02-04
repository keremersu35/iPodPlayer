import SwiftUI

// MARK: - ThemeType Enum
enum ThemeType: String, CaseIterable {
    case silver, dark, u2Edition
}

// MARK: - Theme Protocol
protocol Theme {
    var caseAppearance: String { get }
    var wheelIconTint: Color { get }
    var wheelColor: Color { get }
    var wheelInnerAppearance: String { get }
}

// MARK: - Theme Implementations
struct Silver: Theme {
    var caseAppearance = ImageNames.Custom.lightTheme
    let wheelIconTint = Color.buttonIconTint
    let wheelColor = Color.wheelSilver
    let wheelInnerAppearance = ImageNames.Custom.lightThemeButton
}

struct Dark: Theme {
    var caseAppearance = ImageNames.Custom.darkTheme
    let wheelIconTint = Color.white
    let wheelColor = Color.wheelDark
    let wheelInnerAppearance = ImageNames.Custom.darkThemeButton
}

struct U2Edition: Theme {
    var caseAppearance = ImageNames.Custom.darkTheme
    let wheelIconTint = Color.white
    let wheelColor = Color.wheelU2
    let wheelInnerAppearance = ImageNames.Custom.darkThemeButton
}

// MARK: - Theme Factory
struct ThemeFactory {
    static func createTheme(for type: ThemeType) -> Theme {
        switch type {
        case .silver:
            return Silver()
        case .dark:
            return Dark()
        case .u2Edition:
            return U2Edition()
        }
    }
}

// MARK: - ThemeManager
final class ThemeManager: ObservableObject {
    @Published private(set) var currentTheme: Theme
    private(set) var currentThemeType: ThemeType
    
    init() {
        currentThemeType = .silver
        currentTheme = ThemeFactory.createTheme(for: currentThemeType)
        loadTheme()
    }
    
    private func loadTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: UserDefaultsKeys.currentTheme.rawValue),
           let themeType = ThemeType(rawValue: savedTheme) {
            currentThemeType = themeType
            currentTheme = ThemeFactory.createTheme(for: themeType)
        }
    }
    
    func setTheme(_ themeType: ThemeType) {
        currentThemeType = themeType
        currentTheme = ThemeFactory.createTheme(for: themeType)
        UserDefaults.standard.set(themeType.rawValue, forKey: UserDefaultsKeys.currentTheme.rawValue)
    }
}

