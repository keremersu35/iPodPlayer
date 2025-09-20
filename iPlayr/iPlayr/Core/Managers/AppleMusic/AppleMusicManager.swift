import Foundation
import Combine
import MusicKit

@MainActor
final class AppleMusicManager: ObservableObject {
    
    @Published var currentTrack: Song?
    @Published var isPlaying: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isLast: Bool = false
    @Published private(set) var isFirst: Bool = false
    
    private let musicPlayer = ApplicationMusicPlayer.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSongObserver()
    }

    func play() async throws {
        guard let _ = currentTrack else {
            throw MusicPlayerError.noTrackSelected
        }
        try await musicPlayer.play()
    }

    func pause() {
        musicPlayer.pause()
    }

    func playAlbum(id: String, fromIndex: Int = 0) async throws {
        currentTrack = nil
        let request = MusicLibraryRequest<Album>()
        let response = try await request.response()

        guard let album = response.items.first(where: { $0.id.rawValue == id }) else {
            throw MusicPlayerError.albumNotFound
        }

        let albumWithTracks = try await album.with(.tracks)
        guard let tracks = albumWithTracks.tracks, !tracks.isEmpty else {
            throw MusicPlayerError.trackNotFound
        }

        guard tracks.indices.contains(fromIndex) else {
            throw MusicPlayerError.invalidTrackIndex(index: fromIndex, totalTracks: tracks.count)
        }

        let startingTrack = tracks[fromIndex]
        let queue = ApplicationMusicPlayer.Queue(album: album, startingAt: startingTrack)
        musicPlayer.queue = queue
        musicPlayer.state.shuffleMode = .off
        try await musicPlayer.prepareToPlay()
        try await musicPlayer.play()
    }

    func playPlaylist(id: String, fromIndex: Int = 0) async throws {
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()

        guard let playlist = response.items.first(where: { $0.id.rawValue == id }) else {
            throw MusicPlayerError.playlistNotFound
        }

        let playlistWithTracks = try await playlist.with(.entries)
        guard let tracks = playlistWithTracks.entries, !tracks.isEmpty else {
            throw MusicPlayerError.trackNotFound
        }

        guard tracks.indices.contains(fromIndex) else {
            throw MusicPlayerError.invalidTrackIndex(index: fromIndex, totalTracks: tracks.count)
        }

        let startingTrack = tracks[fromIndex]
        let queue = ApplicationMusicPlayer.Queue(playlist: playlist, startingAt: startingTrack)
        musicPlayer.queue = queue
        musicPlayer.state.shuffleMode = .off
        try await musicPlayer.prepareToPlay()
        try await musicPlayer.play()
    }

    func skipToNextTrack() async throws {
        guard !isLast else { return }
        try await musicPlayer.skipToNextEntry()
    }

    func skipToPreviousTrack() async throws {
        guard !isFirst else { return }
        try await musicPlayer.skipToPreviousEntry()
    }

    func togglePlayPause() async throws {
        if isPlaying {
            musicPlayer.pause()
        } else {
            try await musicPlayer.play()
        }
    }

    private func setupSongObserver() {
        musicPlayer.state.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { [weak self] in
                    guard let self else { return }
                    await updatePlayerState()
                }
            }
            .store(in: &cancellables)
    }

    private func updatePlayerState() async {
        let currentPlayingEntryId = musicPlayer.queue.currentEntry?.id
        isLast = musicPlayer.queue.entries.last?.id == currentPlayingEntryId
        isFirst = musicPlayer.queue.entries.first?.id == currentPlayingEntryId
        await updateCurrentTrack()
        updatePlaybackStatus()
    }

    private func updateCurrentTrack() async {
        if case let .song(song) = musicPlayer.queue.currentEntry?.item {
            currentTrack = song
        }
    }

    private func updatePlaybackStatus() {
        switch musicPlayer.state.playbackStatus {
        case .playing:
            isPlaying = true
            isPaused = false
        case .paused:
            isPlaying = false
            isPaused = true
        default:
            break
        }
    }
}

enum MusicPlayerError: LocalizedError {
    case noTrackSelected
    case albumNotFound
    case playlistNotFound
    case trackNotFound
    case invalidTrackIndex(index: Int, totalTracks: Int)

    var errorDescription: String? {
        switch self {
        case .noTrackSelected:
            return "No track is currently selected."
        case .albumNotFound:
            return "The specified album could not be found."
        case .playlistNotFound:
            return "The specified playlist could not be found."
        case .trackNotFound:
            return "The specified track could not be found."
        case .invalidTrackIndex(let index, let totalTracks):
            return "The track index \(index) is out of range. The item contains \(totalTracks) tracks."
        }
    }
}
