import UIKit

@MainActor
final class BatteryMonitor: ObservableObject {
    @Published private(set) var level: Float
    private nonisolated(unsafe) var observer: NSObjectProtocol?

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        level = UIDevice.current.batteryLevel
        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.level = UIDevice.current.batteryLevel
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
