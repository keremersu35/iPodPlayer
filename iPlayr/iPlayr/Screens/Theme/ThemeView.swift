import SwiftUI

struct ThemeView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var scope = FocusScope(id: "theme", showsRightView: true)
    private var menus: [Menu] = [
        .init(id: 0, name: "Silver", next: false),
        .init(id: 1, name: "Black", next: false),
        .init(id: 2, name: "U2 Edition", next: false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "Themes")
            ForEach(menus, id: \.id) { menu in
                MenuItemView(menu: menu, isSelected: scope.selection == menu.id)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .navigationBarBackButtonHidden()
    }

    private func setup() {
        scope.configure(itemCount: menus.count)
        scope.onAction = { action in
            switch action {
            case .menu:
                dismiss()
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
