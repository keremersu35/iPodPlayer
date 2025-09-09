import SwiftUI
import Combine
import Equatable

@Equatable
struct SettingsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    private var menus: [Menu] = [ .init(id: 0, name: "Themes", next: true)]
    @State private var selectedIndex : Int = 0

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
        .onDisappear(perform: cancelSubscriptions)
    }
    
    private func setup() {
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.activePage = .settings
        iPlayrController.hasRightView = true
        iPlayrController.menuCount = menus.count
        setupButtonListener()
    }
    
    private func setupButtonListener() {
        guard iPlayrController.activePage == .settings else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu:
                    dismiss()
                case .select:
                    navigation()
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func navigation() {
        let route: Route
        switch selectedIndex {
        case 0: route = .theme
        default: route = .theme
        }
        navigate(.push(route))
    }
    
    private func cancelSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
