import SwiftUI
import Combine

struct MusicListView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    private var menus: [Menu] = [
        .init(id: 0, name: "Cover Flow", next: true),
        .init(id: 1, name: "Playlists", next: true),
        .init(id: 2, name: "Albums", next: true),
    ]
    @State private var selectedIndex : Int = 0

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
        .onDisappear(perform: cancelSubscriptions)
    }
    
    private func setupButtonListener() {
        guard iPlayrController.activePage == .music else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu:
                    dismiss()
                case .select:
                    navigation()
                default: break
                }
            }
            .store(in: &cancellables)
    }
    
    private func setup() {
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.hasRightView = true
        iPlayrController.activePage = .music
        iPlayrController.menuCount = menus.count
        setupButtonListener()
    }
    
    private func navigation() {
        guard iPlayrController.activePage == .music else { return }
        let route: Route
        switch selectedIndex {
        case 0: route = .coverFlow
        case 1: route = .playlists
        case 2: route = .albums
        default: route = .playlists
        }
        navigate(.push(route))
    }
    
    private func cancelSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
