import SwiftUI

enum ThemeType: String, CaseIterable {
    case silver, dark, u2Edition
}

protocol Theme {
    var caseAppearance: String { get }
    var wheelIconTint: Color { get }
    var wheelColor: Color { get }
    var wheelInnerAppearance: String { get }
}

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

struct ThemeFactory {
    static func createTheme(for type: ThemeType) -> Theme {
        switch type {
        case .silver: return Silver()
        case .dark: return Dark()
        case .u2Edition: return U2Edition()
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var currentTheme: Theme
    @AppStorage("currentTheme") private var currentThemeType: ThemeType = .silver

    init() {
        self.currentTheme = ThemeFactory.createTheme(for: .silver)
        self.currentTheme = ThemeFactory.createTheme(for: currentThemeType)
    }

    func setTheme(_ themeType: ThemeType) {
        currentThemeType = themeType
        currentTheme = ThemeFactory.createTheme(for: themeType)
    }
}
