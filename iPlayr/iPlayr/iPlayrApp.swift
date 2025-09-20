import SwiftUI

@main
struct iPlayrApp: App {
    @StateObject var theme: ThemeManager = .init()
    @StateObject private var playerManager = AppleMusicManager()

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    var body: some Scene {
        WindowGroup {
            iPlayrView()
                .environmentObject(theme)
                .environmentObject(playerManager)
        }
    }
}
