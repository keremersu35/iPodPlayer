import SwiftUI

@main
struct iPlayrApp: App {
    @State var theme: ThemeManager = .init()
    @State private var playerManager = AppleMusicManager()
    @State private var authManager = MusicAuthorizationManager()
    @State private var libraryStore = MusicLibraryStore()
    @State private var menuPreferences = MenuPreferences()

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    var body: some Scene {
        WindowGroup {
            iPlayrView()
                .environment(theme)
                .environment(playerManager)
                .environment(authManager)
                .environment(libraryStore)
                .environment(menuPreferences)
        }
    }
}
