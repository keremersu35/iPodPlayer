import SwiftUI

@main
struct iPlayrApp: App {
    @StateObject var theme: ThemeManager = .init()
    @StateObject private var playerManager = AppleMusicManager()
    @StateObject private var authManager = MusicAuthorizationManager()
    @StateObject private var batteryMonitor = BatteryMonitor()

    var body: some Scene {
        WindowGroup {
            iPlayrView()
                .environmentObject(theme)
                .environmentObject(playerManager)
                .environmentObject(authManager)
                .environmentObject(batteryMonitor)
        }
    }
}
