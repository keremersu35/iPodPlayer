import SwiftUI

@main
struct iPlayrApp: App {
    @StateObject var theme: ThemeManager = .init()
    @StateObject private var playerManager = AppleMusicManager()
    @StateObject private var authManager = MusicAuthorizationManager()

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    var body: some Scene {
        WindowGroup {
            iPlayrView()
                .environmentObject(theme)
                .environmentObject(playerManager)
                .environmentObject(authManager)
        }
    }
}
