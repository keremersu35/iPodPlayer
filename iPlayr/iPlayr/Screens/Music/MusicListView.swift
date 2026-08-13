import SwiftUI

struct MusicListView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @Environment(\.navigate) private var navigate
    @StateObject private var scope = FocusScope(id: "music", showsRightView: true)
    private var menus: [Menu] = [
        .init(id: 0, name: String(localized: "Cover Flow"), next: true),
        .init(id: 1, name: String(localized: "Playlists"), next: true),
        .init(id: 2, name: String(localized: "Albums"), next: true),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Music"))
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
            navigate(.pop)
        case .select:
            navigation()
        default: break
        }
    }

    private func navigation() {
        let route: Route
        switch scope.selection {
        case 0: route = .coverFlow
        case 1: route = .playlists
        case 2: route = .albums
        default: route = .playlists
        }

        navigate(.push(route))
    }
}
