import Foundation
import UIKit
import AudioToolbox

enum ButtonAction: Sendable {
    case menu, forwardEndAlt, backwardEndAlt, playPause, select
    case forwardLongPress, backwardLongPress, forwardLongPressEnd, backwardLongPressEnd
}

@MainActor
final class iPlayrButtonController: ObservableObject {
    @Published private(set) var activeScope: FocusScope?

    private var globalPlaybackHandler: ((ButtonAction) -> Void)?
    var onMenuLongPress: (() -> Void)?

    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    private var hapticsEnabled: Bool { UserDefaults.standard.object(forKey: UserDefaultsKeys.hapticsEnabled.rawValue) as? Bool ?? true }
    private var soundsEnabled: Bool { UserDefaults.standard.object(forKey: UserDefaultsKeys.soundsEnabled.rawValue) as? Bool ?? true }

    private var lastInteractionTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.3

    init() {
        selectionFeedback.prepare()
        impactFeedback.prepare()
    }

    func activate(_ scope: FocusScope) {
        activeScope = scope
    }

    func setGlobalPlaybackHandler(_ handler: @escaping (ButtonAction) -> Void) {
        self.globalPlaybackHandler = handler
    }

    private func playPressFeedback() {
        if hapticsEnabled {
            impactFeedback.impactOccurred()
            impactFeedback.prepare()
        }
        if soundsEnabled {
            AudioServicesPlaySystemSound(1306)
        }
    }

    private func consumeDebounce() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastInteractionTime) > debounceInterval else { return false }
        lastInteractionTime = now
        return true
    }

    private func handleInput(_ action: ButtonAction) {
        if action == .menu || action == .select {
            guard consumeDebounce() else { return }
            playPressFeedback()
        }

        activeScope?.onAction?(action)

        switch action {
        case .playPause, .forwardEndAlt, .backwardEndAlt:
            if activeScope?.id != "player" {
                globalPlaybackHandler?(action)
            }
        default:
            break
        }
    }

    func menuButtonPressed() { handleInput(.menu) }

    func menuLongPressed() {
        guard consumeDebounce() else { return }
        playPressFeedback()
        onMenuLongPress?()
    }

    func selectButtonPressed() { handleInput(.select) }
    func forwardEndAltButtonPressed() { handleInput(.forwardEndAlt) }
    func backwardEndAltButtonPressed() { handleInput(.backwardEndAlt) }
    func playPauseButtonPressed() { handleInput(.playPause) }

    func forwardLongPressStarted() { handleInput(.forwardLongPress) }
    func forwardLongPressEnded() { handleInput(.forwardLongPressEnd) }
    func backwardLongPressStarted() { handleInput(.backwardLongPress) }
    func backwardLongPressEnded() { handleInput(.backwardLongPressEnd) }

    func scrollUp() {
        guard let scope = activeScope, scope.moveUp() else { return }
        if hapticsEnabled {
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()
        }
    }

    func scrollDown() {
        guard let scope = activeScope, scope.moveDown() else { return }
        if hapticsEnabled {
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()
        }
    }
}
