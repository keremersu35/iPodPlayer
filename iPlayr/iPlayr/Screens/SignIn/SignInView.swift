import SwiftUI
import MusicKit

struct SignInView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var authManager: MusicAuthorizationManager
    @Environment(\.navigate) private var navigate
    @StateObject private var scope = FocusScope(id: "login", showsRightView: true)
    @State private var isShowingModal = false
    @State private var menus: [Menu] = [
        Menu(id: 1, name: String(localized: "Apple Music"), next: true),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Sign In"))
            ForEach(menus.indices, id: \.self) { index in
                MenuItemView(menu: menus[index], isSelected: scope.selection == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
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
        scope.configure(itemCount: menus.count)
        scope.onAction = { action in
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                Task { await handleAppleMusicSignIn() }
            default:
                break
            }
        }
        iPlayrController.activate(scope)
    }

    private func handleAppleMusicSignIn() async {
        let status = authManager.authorizationStatus

        if status == .denied {
            isShowingModal = true
            return
        }

        let granted = await authManager.requestAuthorization()
        if granted {
            navigate(.pop)
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
