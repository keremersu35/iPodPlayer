import Combine
import AVFAudio

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
    @Published private(set) var hasRightView: Bool = true
    @Published var activePage: Page = .home

    // MARK: - Exclusive Input Responder Architecture
    // Sadece tek bir handler aktif olabilir. Combine yayınlarından kurtuluyoruz.
    private var activeInputHandler: ((ButtonAction) -> Void)?

    // View'lar açıldığında bu fonksiyonu çağırarak kontrolü ele alacak
    func takeControl(handler: @escaping (ButtonAction) -> Void) {
        self.activeInputHandler = handler
    }

    // Eğer navigation sırasında kontrolü boşa çıkarmak istersek
    func releaseControl() {
        self.activeInputHandler = nil
    }

    // Eski yapı uyumluluğu için (yavaş yavaş kaldıracağız)
    let buttonPressed = PassthroughSubject<ButtonAction, Never>()

    func setRightView(_ visible: Bool) {
        hasRightView = visible
    }

    private var savedIndices: [Page: Int] = [:]

    private var lastInteractionTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.3 // Debounce hala gerekli

    private func handleInput(_ action: ButtonAction) {
        let now = Date()
        if action == .menu || action == .select {
            guard now.timeIntervalSince(lastInteractionTime) > debounceInterval else { return }
            lastInteractionTime = now
        }

        activeInputHandler?(action)

        // Playback actions always reach PlayerView's subscriber regardless of active page
        switch action {
        case .playPause, .forwardEndAlt, .backwardEndAlt,
             .forwardLongPress, .forwardLongPressEnd, .backwardLongPress, .backwardLongPressEnd:
            buttonPressed.send(action)
        default:
            if activeInputHandler == nil { buttonPressed.send(action) }
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
        // STATE RESET: Yeni sayfaya geçerken handler'ı temizle (View kendi atayana kadar)
        // releaseControl() // Bunu yaparsak View onAppear olana kadar input boşluğa gider. Güvenli.
    }

    func saveCurrentIndex() {
        savedIndices[activePage] = selectedIndex
    }

    func resetIndex(for page: Page) {
        savedIndices[page] = 0
    }
}
