import Foundation
import SwiftUI

enum NavigationType: Hashable {
    case push(Route)
    case unwind(Route)
    case resetTo(Route)
}

struct NavigateAction {
    typealias Action = (NavigationType) -> ()
    let action: Action
    
    func callAsFunction(_ navigationType: NavigationType) {
        action(navigationType)
    }

    func resetToRoot(_ route: Route) {
        action(.resetTo(route))
    }
}

struct NavigationEnvironmentKey: EnvironmentKey {
    static var defaultValue: NavigateAction = NavigateAction(action: { _ in })
}

extension EnvironmentValues {
    var navigate: (NavigateAction) {
        get { self[NavigationEnvironmentKey.self] }
        set { self[NavigationEnvironmentKey.self] = newValue }
    }
}

enum Route: Hashable, Identifiable {
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
    
    var id: Route { self }
}

extension Route {
    
    @ViewBuilder
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
        case .settings:
            SettingsView()
        case .albums:
            AlbumsView()
        case .albumTracks(id: let id, albumName: let albumName):
            AlbumTracksView(collectionInfo: CollectionInfoModel(id: id, title: albumName))
        }
    }
}
