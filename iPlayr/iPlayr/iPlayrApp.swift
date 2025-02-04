import SwiftUI

@main
struct iPlayrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var theme: ThemeManager = .init()
    @StateObject private var playerManager = AppleMusicManager()

    var body: some Scene {
        WindowGroup {
            iPlayrView()
                .environmentObject(theme)
                .environmentObject(playerManager)
        }
    }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return true
    }
}
