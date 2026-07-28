import SwiftUI
import MusicKit

struct SignInView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var authManager: MusicAuthorizationManager
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
    }

    private func setup() {
        iPlayrController.setActivePage(.login, menuCount: menus.count)
        selectedIndex = iPlayrController.selectedIndex

        iPlayrController.takeControl { action in
            switch action {
            case .menu:
                dismiss()
            case .select:
                Task { await handleAppleMusicSignIn() }
            default:
                break
            }
        }
    }

    private func handleAppleMusicSignIn() async {
        let status = authManager.authorizationStatus

        if status == .denied {
            isShowingModal = true
            return
        }

        let granted = await authManager.requestAuthorization()
        if granted {
            dismiss()
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
