import Foundation
import MusicKit

enum MusicLibraryError: LocalizedError, Sendable {
    case albumNotFound
    case playlistNotFound
    case artistNotFound
    case genreNotFound

    var errorDescription: String? {
        switch self {
        case .albumNotFound:
            return "The specified album could not be found."
        case .playlistNotFound:
            return "The specified playlist could not be found."
        case .artistNotFound:
            return "The specified artist could not be found."
        case .genreNotFound:
            return "The specified genre could not be found."
        }
    }
}

actor MusicLibraryService {
    func fetchAlbums() async throws -> [Album] {
        var request = MusicLibraryRequest<Album>()
        request.sort(by: \.title, ascending: true)
        return try await drainBatches(from: request.response().items)
    }

    func fetchPlaylists() async throws -> [Playlist] {
        try await drainBatches(from: MusicLibraryRequest<Playlist>().response().items)
    }

    func fetchArtists() async throws -> [Artist] {
        var request = MusicLibraryRequest<Artist>()
        request.sort(by: \.name, ascending: true)
        return try await drainBatches(from: request.response().items)
    }

    func fetchGenres() async throws -> [Genre] {
        var request = MusicLibraryRequest<Genre>()
        request.sort(by: \.name, ascending: true)
        return try await drainBatches(from: request.response().items)
    }

    func fetchSongs() async throws -> [Song] {
        var request = MusicLibraryRequest<Song>()
        request.sort(by: \.title, ascending: true)
        return try await drainBatches(from: request.response().items)
    }

    func fetchAlbumTracks(id: String) async throws -> [Track] {
        let album = try await fetchAlbum(id: id)
        return Array(try await album.with(.tracks, preferredSource: .library).tracks ?? [])
    }

    func fetchPlaylistTracks(id: String) async throws -> [Track] {
        let playlist = try await fetchPlaylist(id: id)
        return Array(try await playlist.with(.tracks, preferredSource: .library).tracks ?? [])
    }

    func fetchArtistAlbums(id: String) async throws -> [Album] {
        var request = MusicLibraryRequest<Artist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        guard let artist = try await request.response().items.first else {
            throw MusicLibraryError.artistNotFound
        }

        var albumsRequest = MusicLibraryRequest<Album>()
        albumsRequest.filter(matching: \.artists, contains: artist)
        albumsRequest.sort(by: \.title, ascending: true)
        let albums = try await drainBatches(from: albumsRequest.response().items)
        guard albums.isEmpty else { return albums }

        var byNameRequest = MusicLibraryRequest<Album>()
        byNameRequest.filter(matching: \.artistName, equalTo: artist.name)
        byNameRequest.sort(by: \.title, ascending: true)
        return try await drainBatches(from: byNameRequest.response().items)
    }

    func fetchGenreArtists(id: String) async throws -> [Artist] {
        var request = MusicLibraryRequest<Genre>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        guard let genre = try await request.response().items.first else {
            throw MusicLibraryError.genreNotFound
        }
        var artistsRequest = MusicLibraryRequest<Artist>()
        artistsRequest.filter(matching: \.genres, contains: genre)
        artistsRequest.sort(by: \.name, ascending: true)
        return try await drainBatches(from: artistsRequest.response().items)
    }

    func fetchAlbum(id: String) async throws -> Album {
        var request = MusicLibraryRequest<Album>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        guard let album = try await request.response().items.first else {
            throw MusicLibraryError.albumNotFound
        }
        return album
    }

    func fetchPlaylist(id: String) async throws -> Playlist {
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        guard let playlist = try await request.response().items.first else {
            throw MusicLibraryError.playlistNotFound
        }
        return playlist
    }

    private func drainBatches<T: MusicItem>(from firstBatch: MusicItemCollection<T>) async throws -> [T] {
        var batch = firstBatch
        var items = Array(batch)
        while batch.hasNextBatch, let nextBatch = try await batch.nextBatch() {
            items.append(contentsOf: nextBatch)
            batch = nextBatch
        }
        return items
    }
}
