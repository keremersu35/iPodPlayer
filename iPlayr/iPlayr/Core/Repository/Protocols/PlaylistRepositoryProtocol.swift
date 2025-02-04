import MusicKit

protocol PlaylistRepositoryProtocol: AnyObject {
    func currentUserPlaylist() async throws -> MusicItemCollection<Playlist>?
    func getPlaylistTracks(id: String) async throws -> MusicItemCollection<Track>?
}
