import SwiftUI
import MusicKit

struct PlayerView: View {
    let id: String?
    let trackIndex: Int?
    let isFromCoverFlow: Bool
    let isFromPlaylist: Bool
    var initialArtwork: Artwork?
    var onDismissFromCoverFlow: (() -> Void)? = nil
    @State private var activeArtwork: Artwork?
    @Environment(\.navigate) private var navigate
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var playerManager: AppleMusicManager
    @StateObject private var scope = FocusScope(id: "player")
    @State private var currentDegree: Double = 80
    @State private var currentOpacity: Double = 0
    @State private var isScaleAnimation: Bool = true
    @State private var seekTimer: Timer?
    @State private var isSeekingForward: Bool = false
    @State private var isSeekingBackward: Bool = false
    @State private var seekStartTime: Date?
    @State private var currentSeekSpeed: Double = 1.0
    @State private var playbackErrorMessage: String?

    private let initialRotation: Double = 80
    private let finalRotation: Double = 5
    private let flipDuration: Double = 0.6
    private let fadeDelay: Double = 0.3
    private let fadeDuration: Double = 0.4

    var body: some View {
        ZStack {
            playerContent
            if let playbackErrorMessage {
                errorOverlay(playbackErrorMessage)
            }
        }
        .background(Color.white)
        .frame(maxHeight: .infinity)
        .onAppear {
            if let artwork = initialArtwork {
                activeArtwork = artwork
            } else {
                activeArtwork = playerManager.currentTrack?.artwork
            }
            if !isFromCoverFlow {
                currentDegree = finalRotation
                currentOpacity = 1
                isScaleAnimation = false
            }
            setupButtonListener()
            guard let id, let trackIndex else { return }
            Task {
                try? await Task.sleep(for: .seconds(NavigationTiming.pushDuration))
                do {
                    if isFromPlaylist {
                        try await playerManager.playPlaylist(id: id, fromIndex: trackIndex)
                    } else {
                        try await playerManager.playAlbum(id: id, fromIndex: trackIndex)
                    }
                } catch {
                    playbackErrorMessage = error.localizedDescription
                }
            }
        }
        .onDisappear {
            stopSeeking()
        }
    }

    private func errorOverlay(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: ImageNames.System.xCircle)
                .font(.system(size: 40))
                .foregroundColor(.red.opacity(0.6))
            Text(message)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .minimumScaleFactor(0.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private var playerContent: some View {
        VStack(spacing: 0) {
            if !isFromCoverFlow {
                StatusBar(title: String(localized: "Now Playing"))
            }
            Spacer()
            VStack {
                HStack(spacing: 24) {
                    ZStack {
                        if let image = activeArtwork {
                            ArtworkImage(image, width: 150)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150, height: 150)
                                .reflection()
                                .rotation3DEffect(.degrees(currentDegree), axis: (x: 0, y: 1, z: 0))
                                .scaleEffect(isScaleAnimation ? 1.2 : 1)
                                .id(playerManager.currentTrack?.title ?? "")
                                .onAppear {
                                    guard isFromCoverFlow else { return }
                                    isScaleAnimation = true
                                    currentDegree = initialRotation
                                    currentOpacity = 0
                                    DispatchQueue.main.async {
                                        withAnimation(.snappy(duration: flipDuration)) {
                                            isScaleAnimation = false
                                            currentDegree = finalRotation
                                        }
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + fadeDelay) {
                                        withAnimation(.easeInOut(duration: fadeDuration)) {
                                            currentOpacity = 1
                                        }
                                    }
                                }
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 150, height: 150)
                    .onChange(of: playerManager.currentTrack) { _, newValue in
                        if let newArtwork = newValue?.artwork {
                            activeArtwork = newArtwork
                        }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(playerManager.currentTrack?.title ?? "")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .id(playerManager.currentTrack?.title ?? "")
                        Text(playerManager.currentTrack?.artistName ?? "")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                            .id(playerManager.currentTrack?.artistName ?? "")
                        Text(playerManager.currentTrack?.albumTitle ?? "")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                            .id(playerManager.currentTrack?.albumTitle ?? "")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(currentOpacity)
                }
                .frame(height: 180)
                Spacer()
                    .frame(height: 8)
                SongProgressView()
                    .environmentObject(playerManager)
                    .opacity(currentOpacity)
                    .padding(.horizontal, -4)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func setupButtonListener() {
        scope.onAction = { action in
            switch action {
            case .menu:
                if isFromCoverFlow {
                    onDismissFromCoverFlow?()
                } else {
                    navigate(.pop)
                }
            case .select:
                break
            case .forwardEndAlt:
                Task { try? await playerManager.skipToNextTrack() }
            case .backwardEndAlt:
                Task { try? await playerManager.skipToPreviousTrack() }
            case .playPause:
                Task {
                    try? await playerManager.togglePlayPause()
                }
            case .forwardLongPress:
                startSeekingForward()
            case .forwardLongPressEnd:
                stopSeeking()
            case .backwardLongPress:
                startSeekingBackward()
            case .backwardLongPressEnd:
                stopSeeking()
            }
        }
        iPlayrController.activate(scope)
    }

    private func startSeekingForward() {
        guard !isSeekingForward && !isSeekingBackward else { return }
        isSeekingForward = true
        seekStartTime = Date()
        currentSeekSpeed = 1.0

        seekTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task {
                await updateSeekSpeed()
                await playerManager.seekForward(seconds: currentSeekSpeed)
            }
        }
    }

    private func startSeekingBackward() {
        guard !isSeekingForward && !isSeekingBackward else { return }
        isSeekingBackward = true
        seekStartTime = Date()
        currentSeekSpeed = 1.0

        seekTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task {
                await updateSeekSpeed()
                await playerManager.seekBackward(seconds: currentSeekSpeed)
            }
        }
    }

    private func stopSeeking() {
        seekTimer?.invalidate()
        seekTimer = nil
        isSeekingForward = false
        isSeekingBackward = false
        seekStartTime = nil
        currentSeekSpeed = 1.0
    }

    @MainActor
    private func updateSeekSpeed() {
        guard let startTime = seekStartTime else { return }

        let elapsedTime = Date().timeIntervalSince(startTime)
        switch elapsedTime {
        case 0..<1:
            currentSeekSpeed = 1.0
        case 1..<3:
            currentSeekSpeed = 2.0
        case 3..<5:
            currentSeekSpeed = 5.0
        case 5..<10:
            currentSeekSpeed = 10.0
        default:
            currentSeekSpeed = 20.0
        }
    }
}

struct SongProgressView: View {
    @EnvironmentObject private var playerManager: AppleMusicManager

    private var currentDuration: TimeInterval {
        playerManager.currentTrack?.duration ?? 0
    }

    private var visualProgress: Double {
        guard currentDuration > 0 else { return 0 }
        return min(1.0, playerManager.currentPlaybackTime / currentDuration)
    }

    private var barUpdateInterval: TimeInterval { playerManager.isPlaying ? 0.1 : 3600 }
    private var textUpdateInterval: TimeInterval { playerManager.isPlaying ? 1 : 3600 }

    var body: some View {
        HStack(spacing: 0) {
            TimelineView(.periodic(from: .now, by: textUpdateInterval)) { _ in
                Text(formattedTime(from: Int(visualProgress * currentDuration)))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 50)
                    .multilineTextAlignment(.trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    progressTrackBackground
                    TimelineView(.periodic(from: .now, by: barUpdateInterval)) { _ in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.menuItemBackground1,
                                             .menuItemBackground2,
                                             .menuItemBackground3,
                                             .menuItemBackground4,
                                             .menuItemBackground5],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .shadow(.inner(color: .white.opacity(0.3), radius: 4, x: 0, y: 1))
                            )
                            .frame(width: geo.size.width * CGFloat(visualProgress), height: 18)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 18)
            .padding(8)

            TimelineView(.periodic(from: .now, by: textUpdateInterval)) { _ in
                Text("-\(formattedTime(from: Int(currentDuration - (visualProgress * currentDuration))))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 50)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var progressTrackBackground: some View {
        ZStack {
            Rectangle()
                .fill(Color(.white).gradient.shadow(.inner(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)))
                .frame(height: 18)
            Rectangle()
                .fill(Color(.white).gradient.shadow(.inner(color: .black.opacity(0.2), radius: 10, x: 0, y: 2)))
                .frame(height: 18)
        }
    }

    private func formattedTime(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
