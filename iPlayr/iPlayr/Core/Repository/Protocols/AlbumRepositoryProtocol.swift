import MusicKit

@MainActor
protocol AlbumRepositoryProtocol: AnyObject {
    func getAlbumTracks(id: String) async throws -> MusicItemCollection<Track>??
    func getCurrentUserSavedAlbums() async throws -> MusicItemCollection<Album>?
}
