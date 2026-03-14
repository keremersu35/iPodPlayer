import MusicKit
import UIKit
import Combine

@MainActor
final class MusicAuthorizationManager: ObservableObject {
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined
    
    private var cancellables = Set<AnyCancellable>()
    
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
