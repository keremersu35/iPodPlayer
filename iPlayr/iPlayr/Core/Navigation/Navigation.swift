import Foundation
import SwiftUI

enum NavigationTiming {
    static let pushDuration: Double = 0.28
}

extension View {
    func taskAfterPush(_ action: @escaping @MainActor @Sendable () async -> Void) -> some View {
        task {
            try? await Task.sleep(for: .seconds(NavigationTiming.pushDuration))
            await action()
        }
    }
}

enum NavigationType: Hashable, Sendable {
    case push(Route)
    case pop
    case popToRoot
}

struct NavigateAction: Sendable {
    typealias Action = @MainActor @Sendable (NavigationType) -> Void
    let action: Action

    @MainActor
    func callAsFunction(_ navigationType: NavigationType) {
        action(navigationType)
    }
}

struct NavigationEnvironmentKey: EnvironmentKey {
    static let defaultValue: NavigateAction = NavigateAction(action: { _ in })
}

extension EnvironmentValues {
    var navigate: NavigateAction {
        get { self[NavigationEnvironmentKey.self] }
        set { self[NavigationEnvironmentKey.self] = newValue }
    }
}

enum Route: Hashable, Identifiable, Sendable {
    case music
    case home
    case playlists
    case playlistTracks(id: String, playlistName: String)
    case albumTracks(id: String, albumName: String)
    case signIn
    case coverFlow
    case theme
    case player(id: String, trackIndex: Int, isFromCoverFlow: Bool = false, isFromPlaylist: Bool = false)
    case settings
    case albums
    case nowPlaying

    var id: Route { self }
}

extension Route {
    var isFullScreen: Bool {
        switch self {
        case .home, .music, .settings, .signIn, .theme:
            return false
        case .playlists, .albums, .playlistTracks, .albumTracks, .coverFlow, .player, .nowPlaying:
            return true
        }
    }

    @MainActor @ViewBuilder
    var destination: some View {
        switch self {
        case .music:
            MusicListView()
        case .home:
            HomeListView()
        case .playlists:
            PlaylistsView()
        case .playlistTracks(let id, let playlistName):
            PlaylistTracksView(collectionInfo: CollectionInfoModel(id: id, title: playlistName))
        case .signIn:
            SignInView()
        case .coverFlow:
            CoverFlowView()
        case .theme:
            ThemeView()
        case .player(let id, let trackIndex, let isFromCoverFlow, let isFromPlaylist):
            PlayerView(id: id, trackIndex: trackIndex, isFromCoverFlow: isFromCoverFlow, isFromPlaylist: isFromPlaylist)
        case .nowPlaying:
            PlayerView(id: nil, trackIndex: nil, isFromCoverFlow: false, isFromPlaylist: false)
        case .settings:
            SettingsView()
        case .albums:
            AlbumsView()
        case .albumTracks(id: let id, albumName: let albumName):
            AlbumTracksView(collectionInfo: CollectionInfoModel(id: id, title: albumName))
        }
    }
}
