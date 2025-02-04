import Foundation
import MusicKit

final class PlaylistRepositoryImpl: PlaylistRepositoryProtocol {
    
    public init() {}

    func currentUserPlaylist() async throws -> MusicItemCollection<Playlist>? {
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()
        return response.items
    }
    
    func getPlaylistTracks(id: String) async throws -> MusicItemCollection<Track>? {
        guard let playlist = try await fetchPlaylist(id: id)?.with(.tracks) else {
            throw NSError(domain: "MusicKitPlaylist", code: 2, userInfo: [NSLocalizedDescriptionKey: "Playlist not found."])
        }
        return playlist.tracks
    }
    
    private func fetchPlaylist(id: String) async throws -> Playlist? {
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()
        return response.items.first { $0.id.rawValue == id }
    }
}
