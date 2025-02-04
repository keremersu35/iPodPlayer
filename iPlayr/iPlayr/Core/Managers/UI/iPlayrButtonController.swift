import Combine
import AVFAudio

enum ButtonAction {
    case menu, forwardEndAlt, backwardEndAlt, playPause, select
}

enum Pages {
    case home, music, login, playlists, albumTracks, playlistTracks, coverFlow,
         coverFlowSongList, player, theme, settings, albums
}

final class iPlayrButtonController: ObservableObject {
    @Published var selectedIndex: Int = 0
    @Published var menuCount: Int = 0
    @Published var hasRightView: Bool = true
    let buttonPressed = PassthroughSubject<ButtonAction, Never>()
    @Published var activePage: Pages = .music

    func menuButtonPressed() {
        buttonPressed.send(.menu)
    }
    
    func selectButtonPressed() {
        buttonPressed.send(.select)
    }
    
    func forwardEndAltButtonPressed() {
        buttonPressed.send(.forwardEndAlt)
    }
    
    func backwardEndAltButtonPressed() {
        buttonPressed.send(.backwardEndAlt)
    }
    
    func playPauseButtonPressed() {
        buttonPressed.send(.playPause)
    }

    func scrollUp() {
        selectedIndex -= 1
    }
    
    func scrollDown() {
        selectedIndex += 1
    }
}
