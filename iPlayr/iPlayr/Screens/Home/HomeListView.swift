import SwiftUI
import MusicKit
import Combine
import Equatable

@Equatable
struct HomeListView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @Environment(\.navigate) private var navigate
    private var menus: [Menu] {
        var baseMenus: [Menu] = [
            .init(id: 0, name: "Music", next: true),
            .init(id: 1, name: "Settings", next: true),
        ]
        if MusicAuthorization.currentStatus != .authorized {
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
        .onDisappear(perform: cancelSubscriptions)
    }
    
    private func setup() {
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.activePage = .home
        iPlayrController.menuCount = menus.count
        setupButtonListener()
        iPlayrController.hasRightView = true
    }
    
    private func setupButtonListener() {
        guard iPlayrController.activePage == .home else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .select: navigation()
                case .playPause: break
                default: break
                }
            }
            .store(in: &cancellables)
    }
    
    private func navigation() {
        let route: Route
        switch selectedIndex {
        case 0: route = .music
        case 1: route = .settings
        case 2: route = .signIn
        default: route = .music
        }
        navigate(.push(route))
    }
    
    private func cancelSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
