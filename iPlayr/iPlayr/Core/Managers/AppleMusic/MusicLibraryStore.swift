import MusicKit
import Observation

@MainActor
@Observable
final class MusicLibraryStore {
    private(set) var albums: [Album]?
    private(set) var playlists: [Playlist]?
    private(set) var artists: [Artist]?
    private(set) var genres: [Genre]?
    private(set) var songs: [Song]?
    private(set) var composers: [String]?
    var errorMessage: String?

    @ObservationIgnored private let service = MusicLibraryService()
    @ObservationIgnored private var albumTracksCache: [String: [Track]] = [:]
    @ObservationIgnored private var playlistTracksCache: [String: [Track]] = [:]
    @ObservationIgnored private var artistAlbumsCache: [String: [Album]] = [:]
    @ObservationIgnored private var genreArtistsCache: [String: [Artist]] = [:]

    func loadAlbumsIfNeeded() async {
        guard albums == nil else { return }
        albums = await fetch { try await service.fetchAlbums() }
    }

    func loadPlaylistsIfNeeded() async {
        guard playlists == nil else { return }
        playlists = await fetch { try await service.fetchPlaylists() }
    }

    func loadArtistsIfNeeded() async {
        guard artists == nil else { return }
        artists = await fetch { try await service.fetchArtists() }
    }

    func loadGenresIfNeeded() async {
        guard genres == nil else { return }
        genres = await fetch { try await service.fetchGenres() }
    }

    func loadSongsIfNeeded() async {
        guard songs == nil else { return }
        songs = await fetch { try await service.fetchSongs() }
    }

    func loadComposersIfNeeded() async {
        guard composers == nil else { return }
        await loadSongsIfNeeded()
        guard let songs else { return }
        let names = songs.compactMap { $0.composerName?.trimmingCharacters(in: .whitespacesAndNewlines) }
        composers = Set(names.filter { !$0.isEmpty })
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func composerSongs(name: String) -> [Song] {
        songs?.filter { $0.composerName?.trimmingCharacters(in: .whitespacesAndNewlines) == name } ?? []
    }

    func cachedAlbumTracks(id: String) -> [Track]? { albumTracksCache[id] }
    func cachedPlaylistTracks(id: String) -> [Track]? { playlistTracksCache[id] }
    func cachedArtistAlbums(id: String) -> [Album]? { artistAlbumsCache[id] }
    func cachedGenreArtists(id: String) -> [Artist]? { genreArtistsCache[id] }

    func albumTracks(id: String) async -> [Track]? {
        if let cached = albumTracksCache[id] { return cached }
        guard let tracks = await fetch({ try await service.fetchAlbumTracks(id: id) }) else { return nil }
        albumTracksCache[id] = tracks
        return tracks
    }

    func playlistTracks(id: String) async -> [Track]? {
        if let cached = playlistTracksCache[id] { return cached }
        guard let tracks = await fetch({ try await service.fetchPlaylistTracks(id: id) }) else { return nil }
        playlistTracksCache[id] = tracks
        return tracks
    }

    func artistAlbums(id: String) async -> [Album]? {
        if let cached = artistAlbumsCache[id] { return cached }
        guard let albums = await fetch({ try await service.fetchArtistAlbums(id: id) }) else { return nil }
        artistAlbumsCache[id] = albums
        return albums
    }

    func genreArtists(id: String) async -> [Artist]? {
        if let cached = genreArtistsCache[id] { return cached }
        guard let artists = await fetch({ try await service.fetchGenreArtists(id: id) }) else { return nil }
        genreArtistsCache[id] = artists
        return artists
    }

    private func fetch<T>(_ operation: () async throws -> [T]) async -> [T]? {
        do {
            return try await operation()
        } catch {
            errorMessage = String(localized: "Request failed with error: \(error.localizedDescription)")
            return nil
        }
    }
}
