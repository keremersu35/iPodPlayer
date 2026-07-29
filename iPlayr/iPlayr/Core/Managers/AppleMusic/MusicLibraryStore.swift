import Combine
import MusicKit

@MainActor
final class MusicLibraryStore: ObservableObject {
    @Published private(set) var albums: [Album]?
    @Published private(set) var playlists: [Playlist]?
    @Published var errorMessage: String?

    private let service = MusicLibraryService()
    private var albumTracksCache: [String: [Track]] = [:]
    private var playlistTracksCache: [String: [Track]] = [:]

    func loadAlbumsIfNeeded() async {
        guard albums == nil else { return }
        do {
            albums = try await service.fetchAlbums()
        } catch {
            errorMessage = String(localized: "Request failed with error: \(error.localizedDescription)")
        }
    }

    func loadPlaylistsIfNeeded() async {
        guard playlists == nil else { return }
        do {
            playlists = try await service.fetchPlaylists()
        } catch {
            errorMessage = String(localized: "Request failed with error: \(error.localizedDescription)")
        }
    }

    func albumTracks(id: String) async -> [Track]? {
        if let cached = albumTracksCache[id] { return cached }
        do {
            let tracks = try await service.fetchAlbumTracks(id: id)
            albumTracksCache[id] = tracks
            return tracks
        } catch {
            errorMessage = String(localized: "Request failed with error: \(error.localizedDescription)")
            return nil
        }
    }

    func playlistTracks(id: String) async -> [Track]? {
        if let cached = playlistTracksCache[id] { return cached }
        do {
            let tracks = try await service.fetchPlaylistTracks(id: id)
            playlistTracksCache[id] = tracks
            return tracks
        } catch {
            errorMessage = String(localized: "Request failed with error: \(error.localizedDescription)")
            return nil
        }
    }
}
