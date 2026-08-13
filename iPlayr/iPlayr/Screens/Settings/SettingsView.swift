import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @Environment(\.navigate) private var navigate
    @AppStorage(UserDefaultsKeys.hapticsEnabled.rawValue) private var hapticsEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.soundsEnabled.rawValue) private var soundsEnabled: Bool = true
    @StateObject private var scope = FocusScope(id: "settings")

    private var menus: [Menu] {
        [
            .init(id: 0, name: String(localized: "Themes"), next: true),
            .init(id: 1, name: String(localized: "Haptics"), next: false, value: hapticsEnabled ? String(localized: "On") : String(localized: "Off")),
            .init(id: 2, name: String(localized: "Sounds"), next: false, value: soundsEnabled ? String(localized: "On") : String(localized: "Off")),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Settings"))
            ForEach(menus.indices, id: \.self) { index in
                MenuItemView(menu: menus[index], isSelected: scope.selection == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
    }

    private func setup() {
        scope.configure(itemCount: menus.count)
        scope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            navigate(.pop)
        case .select:
            handleSelect()
        default:
            break
        }
    }

    private func handleSelect() {
        switch scope.selection {
        case 0:
            navigate(.push(.theme))
        case 1:
            hapticsEnabled.toggle()
        case 2:
            soundsEnabled.toggle()
        default:
            break
        }
    }
}
