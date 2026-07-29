import Foundation
import MusicKit

enum MusicLibraryError: LocalizedError, Sendable {
    case albumNotFound
    case playlistNotFound

    var errorDescription: String? {
        switch self {
        case .albumNotFound:
            return "The specified album could not be found."
        case .playlistNotFound:
            return "The specified playlist could not be found."
        }
    }
}

actor MusicLibraryService {
    func fetchAlbums() async throws -> [Album] {
        let request = MusicLibraryRequest<Album>()
        let response = try await request.response()
        return Array(response.items)
    }

    func fetchAlbumTracks(id: String) async throws -> [Track] {
        var request = MusicLibraryRequest<Album>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        let response = try await request.response()
        guard let album = response.items.first else {
            throw MusicLibraryError.albumNotFound
        }
        let albumWithTracks = try await album.with(.tracks)
        return Array(albumWithTracks.tracks ?? [])
    }

    func fetchPlaylists() async throws -> [Playlist] {
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()
        return Array(response.items)
    }

    func fetchPlaylistTracks(id: String) async throws -> [Track] {
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        let response = try await request.response()
        guard let playlist = response.items.first else {
            throw MusicLibraryError.playlistNotFound
        }
        let playlistWithTracks = try await playlist.with(.tracks)
        return Array(playlistWithTracks.tracks ?? [])
    }
}
