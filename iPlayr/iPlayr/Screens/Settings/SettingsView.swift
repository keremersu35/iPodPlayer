import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @AppStorage(UserDefaultsKeys.hapticsEnabled.rawValue) private var hapticsEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.soundsEnabled.rawValue) private var soundsEnabled: Bool = true
    @StateObject private var scope = FocusScope(id: "settings", showsRightView: true)

    private var menus: [Menu] {
        [
            .init(id: 0, name: "Themes", next: true),
            .init(id: 1, name: "Haptics", next: false, value: hapticsEnabled ? "On" : "Off"),
            .init(id: 2, name: "Sounds", next: false, value: soundsEnabled ? "On" : "Off"),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "Settings")
            ForEach(menus.indices, id: \.self) { index in
                MenuItemView(menu: menus[index], isSelected: scope.selection == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .navigationBarBackButtonHidden()
    }

    private func setup() {
        scope.configure(itemCount: menus.count)
        scope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            dismiss()
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
