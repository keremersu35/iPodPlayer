import SwiftUI

struct ThemeView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(\.navigate) private var navigate
    @Environment(ThemeManager.self) private var theme
    @State private var scope = FocusScope(id: "theme")
    private var menus: [Menu] = [
        .init(id: 0, name: String(localized: "Silver"), next: false),
        .init(id: 1, name: String(localized: "Black"), next: false),
        .init(id: 2, name: String(localized: "U2 Edition"), next: false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Themes"))
            ForEach(menus, id: \.id) { menu in
                MenuItemView(menu: menu, isSelected: scope.selection == menu.id)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
    }

    private func setup() {
        scope.configure(itemCount: menus.count)
        scope.onAction = { action in
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                setTheme()
            default:
                break
            }
        }
        iPlayrController.activate(scope)
    }

    private func setTheme() {
        withAnimation {
            let themes: [ThemeType] = [.silver, .dark, .u2Edition]
            theme.setTheme(themes[scope.selection])
        }
    }
}
