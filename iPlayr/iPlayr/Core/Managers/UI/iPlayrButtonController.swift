import Foundation
import UIKit
import AudioToolbox

enum ButtonAction: Sendable {
    case menu, forwardEndAlt, backwardEndAlt, playPause, select
    case forwardLongPress, backwardLongPress, forwardLongPressEnd, backwardLongPressEnd
}

enum Page: Sendable {
    case home, music, login, playlists, albumTracks, playlistTracks, coverFlow,
         coverFlowSongList, player, theme, settings, albums
}

@MainActor
final class iPlayrButtonController: ObservableObject {
    @Published var selectedIndex: Int = 0
    @Published var menuCount: Int = 0
    @Published var activePage: Page = .home

    var hasRightView: Bool {
        switch activePage {
        case .home, .music, .settings, .theme, .login:
            return true
        default:
            return false
        }
    }

    private var activeInputHandler: ((ButtonAction) -> Void)?
    private var globalPlaybackHandler: ((ButtonAction) -> Void)?

    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    private var hapticsEnabled: Bool { UserDefaults.standard.object(forKey: UserDefaultsKeys.hapticsEnabled.rawValue) as? Bool ?? true }
    private var soundsEnabled: Bool { UserDefaults.standard.object(forKey: UserDefaultsKeys.soundsEnabled.rawValue) as? Bool ?? true }

    init() {
        selectionFeedback.prepare()
        impactFeedback.prepare()
    }

    func takeControl(handler: @escaping (ButtonAction) -> Void) {
        self.activeInputHandler = handler
    }

    func releaseControl() {
        self.activeInputHandler = nil
    }

    func setGlobalPlaybackHandler(_ handler: @escaping (ButtonAction) -> Void) {
        self.globalPlaybackHandler = handler
    }

    private var savedIndices: [Page: Int] = [:]

    private var lastInteractionTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.3

    private func handleInput(_ action: ButtonAction) {
        let now = Date()
        if action == .menu || action == .select {
            guard now.timeIntervalSince(lastInteractionTime) > debounceInterval else { return }
            lastInteractionTime = now
            if hapticsEnabled {
                impactFeedback.impactOccurred()
                impactFeedback.prepare()
            }
            if soundsEnabled {
                AudioServicesPlaySystemSound(1306)
            }
        }

        activeInputHandler?(action)

        switch action {
        case .playPause, .forwardEndAlt, .backwardEndAlt:
            if activePage != .player {
                globalPlaybackHandler?(action)
            }
        default:
            break
        }
    }

    func menuButtonPressed() { handleInput(.menu) }
    func selectButtonPressed() { handleInput(.select) }
    func forwardEndAltButtonPressed() { handleInput(.forwardEndAlt) }
    func backwardEndAltButtonPressed() { handleInput(.backwardEndAlt) }
    func playPauseButtonPressed() { handleInput(.playPause) }

    func forwardLongPressStarted() { handleInput(.forwardLongPress) }
    func forwardLongPressEnded() { handleInput(.forwardLongPressEnd) }
    func backwardLongPressStarted() { handleInput(.backwardLongPress) }
    func backwardLongPressEnded() { handleInput(.backwardLongPressEnd) }

    func scrollUp() {
        guard menuCount > 0 else { return }
        selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : menuCount - 1
        if hapticsEnabled {
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()
        }
    }

    func scrollDown() {
        guard menuCount > 0 else { return }
        selectedIndex = selectedIndex < menuCount - 1 ? selectedIndex + 1 : 0
        if hapticsEnabled {
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()
        }
    }

    func setActivePage(_ page: Page, menuCount: Int) {
        saveCurrentIndex()
        activePage = page
        self.menuCount = menuCount
        let restoredIndex = savedIndices[page] ?? 0
        selectedIndex = menuCount > 0 ? min(restoredIndex, menuCount - 1) : 0
    }

    func saveCurrentIndex() {
        savedIndices[activePage] = selectedIndex
    }

    func resetIndex(for page: Page) {
        savedIndices[page] = 0
    }
}
