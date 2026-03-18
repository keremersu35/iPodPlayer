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
    
    private nonisolated(unsafe) let musicPlayer = ApplicationMusicPlayer.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSongObserver()
    }

    func playAlbum(id: String, fromIndex: Int = 0) async throws {
        currentTrack = nil
        var request = MusicLibraryRequest<Album>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        let response = try await request.response()

        guard let album = response.items.first else {
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
        currentTrack = nil
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        let response = try await request.response()

        guard let playlist = response.items.first else {
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
        await updatePlayerState()
    }

    func skipToPreviousTrack() async throws {
        guard !isFirst else { return }
        try await musicPlayer.skipToPreviousEntry()
        await updatePlayerState()
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
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.updatePlayerState()
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
        case .stopped, .interrupted:
            isPlaying = false
            isPaused = false
        default:
            break
        }
    }

    func seekForward(seconds: Double = 5.0) {
        let currentTime = musicPlayer.playbackTime
        guard let duration = currentTrack?.duration else { return }
        let newTime = min(currentTime + seconds, duration)
        musicPlayer.playbackTime = newTime
    }

    func seekBackward(seconds: Double = 5.0) {
        let currentTime = musicPlayer.playbackTime
        let newTime = max(currentTime - seconds, 0.0)
        musicPlayer.playbackTime = newTime
    }

    var currentPlaybackTime: TimeInterval {
        return musicPlayer.playbackTime
    }
}

enum MusicPlayerError: LocalizedError, Sendable {
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
