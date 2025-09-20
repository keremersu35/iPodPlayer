import MusicKit
import Foundation

final class AlbumRepositoryImpl: AlbumRepositoryProtocol {
    
    func getAlbumTracks(id: String) async throws -> MusicItemCollection<Track>?? {
        guard let album = try await fetchTracks(id: id)?.with(.tracks) else {
            throw NSError(domain: "MusicKitPlaylist", code: 2, userInfo: [NSLocalizedDescriptionKey: "Playlist not found."])
        }
        return album.tracks
    }
    
    func getCurrentUserSavedAlbums() async throws -> MusicItemCollection<Album>? {
        let request = MusicLibraryRequest<Album>()
        let response = try await request.response()
        return response.items
    }
    
    private func fetchTracks(id: String) async throws -> Album? {
        let request = MusicLibraryRequest<Album>()
        let response = try await request.response()
        return response.items.first { $0.id.rawValue == id }
    }
}
