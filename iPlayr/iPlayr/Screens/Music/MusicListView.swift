import SwiftUI

struct MusicListView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    private var menus: [Menu] = [
        .init(id: 0, name: "Cover Flow", next: true),
        .init(id: 1, name: "Playlists", next: true),
        .init(id: 2, name: "Albums", next: true),
    ]
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "Music")
            ForEach(menus.indices, id: \.self) { index in
                MenuItemView(menu: menus[index], isSelected: selectedIndex == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .onChange(of: iPlayrController.selectedIndex) { _, newValue in
            guard iPlayrController.activePage == .music else { return }
            selectedIndex = newValue
        }
        .navigationBarBackButtonHidden()
        .onDisappear {
            iPlayrController.saveCurrentIndex()
        }
    }

    private func setup() {
        iPlayrController.setActivePage(.music, menuCount: menus.count)
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
            navigation()
        default: break
        }
    }

    private func navigation() {
        iPlayrController.releaseControl()

        guard iPlayrController.activePage == .music else { return }

        let route: Route
        switch selectedIndex {
        case 0: route = .coverFlow
        case 1: route = .playlists
        case 2: route = .albums
        default: route = .playlists
        }

        iPlayrController.saveCurrentIndex()
        DispatchQueue.main.async { navigate(.push(route)) }
    }
}
