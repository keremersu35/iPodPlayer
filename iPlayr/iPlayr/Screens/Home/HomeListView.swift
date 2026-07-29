import SwiftUI
import MusicKit

struct HomeListView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var authManager: MusicAuthorizationManager
    @Environment(\.navigate) private var navigate
    @StateObject private var scope = FocusScope(id: "home", showsRightView: true)

    private var menus: [Menu] {
        var baseMenus: [Menu] = [
            .init(id: 0, name: "Music", next: true),
            .init(id: 1, name: "Settings", next: true),
        ]
        if !authManager.isAuthorized {
            baseMenus.append(.init(id: 2, name: "Sign In", next: true))
        }
        return baseMenus
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "iPlayr")
            ForEach(menus.indices, id: \.self) { index in
                MenuItemView(menu: menus[index], isSelected: scope.selection == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .navigationBarBackButtonHidden()
        .onAppear(perform: setup)
        .onChange(of: authManager.isAuthorized) { _, isAuthorized in
            if isAuthorized {
                scope.configure(itemCount: menus.count)
                iPlayrController.activate(scope)
            }
        }
    }

    private func setup() {
        scope.configure(itemCount: menus.count)
        scope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .select: navigation()
        case .playPause: break
        default: break
        }
    }

    private func navigation() {
        let route: Route
        switch scope.selection {
        case 0: route = .music
        case 1:
            route = .settings
        case 2:
            route = .signIn
        default: route = .music
        }
        navigate(.push(route))
    }

}
