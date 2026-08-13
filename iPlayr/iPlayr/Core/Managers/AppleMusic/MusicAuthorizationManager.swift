import MusicKit
import UIKit
import Combine
import Observation

@MainActor
@Observable
final class MusicAuthorizationManager {
    private(set) var isAuthorized: Bool = false
    private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    
    init() {
        updateAuthorizationStatus()
        observeAppLifecycle()
    }
    
    func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        isAuthorized = status == .authorized
        return isAuthorized
    }
    
    func updateAuthorizationStatus() {
        authorizationStatus = MusicAuthorization.currentStatus
        isAuthorized = authorizationStatus == .authorized
    }
    
    private func observeAppLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.updateAuthorizationStatus()
            }
            .store(in: &cancellables)
    }
}
