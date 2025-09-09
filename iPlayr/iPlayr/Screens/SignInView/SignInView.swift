import SwiftUI
import MusicKit
import Combine

struct SignInView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingModal = false
    @State private var menus: [Menu] = [
        Menu(id: 1, name: "Apple Music", next: true),
    ]
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "Sign In")
            ForEach(menus.indices, id: \.self) { index in
                MenuItemView(menu: menus[index], isSelected: selectedIndex == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .onChange(of: iPlayrController.selectedIndex) { _, newValue in
            guard iPlayrController.activePage == .login else { return }
            selectedIndex = newValue
        }
        .alert("Permission Required", isPresented: $isShowingModal) {
            Button("Go to Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This app requires access to Apple Music. Please enable it in Settings.")
        }
        .navigationBarBackButtonHidden()
        .onDisappear(perform: cancelSubscriptions)
    }

    private func setup() {
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.activePage = .login
        iPlayrController.hasRightView = true
        iPlayrController.menuCount = menus.count
        setupButtonListener()
    }

    private func setupButtonListener() {
        guard iPlayrController.activePage == .login else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu:
                    dismiss()
                case .select:
                    Task {
                        let status = MusicAuthorization.currentStatus
                        if status == .denied {
                            isShowingModal = true
                        } else {
                            _ = await MusicAuthorization.request()
                        }
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func cancelSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
