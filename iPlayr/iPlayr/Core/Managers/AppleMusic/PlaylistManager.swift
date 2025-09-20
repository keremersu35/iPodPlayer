import Combine
import SwiftUI
import MusicKit

final class PlaylistManager: ObservableObject {
    @Published var playlists: MusicItemCollection<Playlist>?
    @Published var playlistsCount: Int = 0
    @Published var tracks: MusicItemCollection<Track>?
    @Published var errorMessage: String?
    private let playlistRepository: PlaylistRepositoryProtocol
    
    init() {
        playlistRepository = PlaylistRepositoryImpl()
    }
    
    func fetchPlaylists() async {
        do {
            let playlists = try await playlistRepository.currentUserPlaylist()
            await MainActor.run {
                self.playlists = playlists ?? []
                self.playlistsCount = playlists?.count ?? 0
            }
        } catch {
            errorMessage = "Request failed with error: \(error.localizedDescription)"
        }
    }

    func getPlaylistTracks(_ id: String) async {
        do {
            let tracks = try await playlistRepository.getPlaylistTracks(id: id)
            await MainActor.run {
                self.tracks = tracks
            }
        } catch {
            errorMessage = "Request failed with error: \(error.localizedDescription)"
        }
    }
}
