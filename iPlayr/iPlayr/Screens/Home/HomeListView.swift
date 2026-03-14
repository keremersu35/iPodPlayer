import SwiftUI
import MusicKit
import Combine

struct HomeListView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var authManager: MusicAuthorizationManager
    @Environment(\.navigate) private var navigate
    
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
    
    @State private var selectedIndex: Int = 0
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "iPlayr")
            ForEach(menus.indices, id: \.self) { index in
                MenuItemView(menu: menus[index], isSelected: selectedIndex == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .navigationBarBackButtonHidden()
        .onAppear(perform: setup)
        .onChange(of: iPlayrController.selectedIndex) { _, newValue in
            guard iPlayrController.activePage == .home else { return }
            selectedIndex = newValue
        }
        .onChange(of: authManager.isAuthorized) { _, isAuthorized in
            if isAuthorized {
                iPlayrController.resetIndex(for: .home)
                iPlayrController.setActivePage(.home, menuCount: menus.count)
                iPlayrController.setRightView(true)
                selectedIndex = iPlayrController.selectedIndex
            }
        }
        .onDisappear {
            iPlayrController.saveCurrentIndex()
            cancelSubscriptions()
        }
    }
    
    private func setup() {
        iPlayrController.setActivePage(.home, menuCount: menus.count)
        iPlayrController.setRightView(true)
        selectedIndex = iPlayrController.selectedIndex
        
        iPlayrController.takeControl { action in
            handleButtonAction(action)
        }
    }
    
    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .select: navigation()
        case .playPause: break
        default: break
        }
    }
    
    private func navigation() {
        iPlayrController.releaseControl()
        let route: Route
        switch selectedIndex {
        case 0: route = .music
        case 1:
            iPlayrController.setRightView(false)
            route = .settings
        case 2:
            route = .signIn
        default: route = .music
        }
        navigate(.push(route))
    }
    
    private func cancelSubscriptions() {
        cancellables.cancelAll()
    }
}
