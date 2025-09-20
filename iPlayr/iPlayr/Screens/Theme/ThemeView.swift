import SwiftUI
import Combine

struct ThemeView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    private var menus: [Menu] = [
        .init(id: 0, name: "Silver", next: false),
        .init(id: 1, name: "Black", next: false),
        .init(id: 2, name: "U2 Edition", next: false),
    ]
    @State private var selectedIndex : Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "Themes")
            ForEach(menus, id: \.id) { menu in
                MenuItemView(menu: menu, isSelected: selectedIndex == menu.id)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .onChange(of: iPlayrController.selectedIndex) { _, newValue in
            guard iPlayrController.activePage == .theme else { return }
            selectedIndex = newValue
        }
        .navigationBarBackButtonHidden()
        .onDisappear(perform: cancelSubscriptions)
    }
    
    private func setup() {
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.activePage = .theme
        setupButtonListener()
    }
    
    private func setupButtonListener() {
        guard iPlayrController.activePage == .theme else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu:
                    dismiss()
                case .select:
                    setTheme()
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func setTheme() {
        withAnimation {
            let themes: [ThemeType] = [.silver, .dark, .u2Edition]
            theme.setTheme(themes[selectedIndex])
        }
    }
    
    private func cancelSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
