import Foundation

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
        if selectedIndex > 0 {
            selectedIndex -= 1
        } else {
            selectedIndex = menuCount - 1
        }
    }

    func scrollDown() {
        if selectedIndex < menuCount - 1 {
            selectedIndex += 1
        } else {
            selectedIndex = 0
        }
    }

    func setActivePage(_ page: Page, menuCount: Int) {
        saveCurrentIndex()
        activePage = page
        self.menuCount = menuCount
        selectedIndex = savedIndices[page] ?? 0
    }

    func saveCurrentIndex() {
        savedIndices[activePage] = selectedIndex
    }

    func resetIndex(for page: Page) {
        savedIndices[page] = 0
    }
}
