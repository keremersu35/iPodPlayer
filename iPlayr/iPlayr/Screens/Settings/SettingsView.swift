import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @AppStorage(UserDefaultsKeys.hapticsEnabled.rawValue) private var hapticsEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.soundsEnabled.rawValue) private var soundsEnabled: Bool = true
    @State private var selectedIndex: Int = 0

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
                MenuItemView(menu: menus[index], isSelected: selectedIndex == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .onChange(of: iPlayrController.selectedIndex) { _, newValue in
            guard iPlayrController.activePage == .settings else { return }
            selectedIndex = newValue
        }
        .navigationBarBackButtonHidden()
        .onDisappear {
            iPlayrController.saveCurrentIndex()
        }
    }

    private func setup() {
        iPlayrController.setActivePage(.settings, menuCount: menus.count)
        selectedIndex = iPlayrController.selectedIndex

        iPlayrController.takeControl { action in
            handleButtonAction(action)
        }
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
        switch selectedIndex {
        case 0:
            iPlayrController.releaseControl()
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
