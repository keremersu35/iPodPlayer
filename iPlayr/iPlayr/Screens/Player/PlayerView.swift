import SwiftUI
import _MusicKit_SwiftUI
import Combine
import Equatable

@Equatable
struct PlayerView: View {
    @State var id: String
    @State var trackIndex: Int
    @State var isFromCoverFlow: Bool = false
    @State var isFromPlaylist: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @StateObject private var playerManager = AppleMusicManager()
    @State private var currentDegree : Double = 80
    @State private var currentOpacity : Double = 0
    @State private var isScaleAnimation: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            if !isFromCoverFlow {
                StatusBar(title: "Now Playing")
            }
            Spacer()
            VStack {
                HStack(spacing: 24) {
                    ZStack {
                        if let image = playerManager.currentTrack?.artwork {
                            ArtworkImage(image, width: 150)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150, height: 150)
                                .reflection()
                                .rotation3DEffect(.degrees(currentDegree), axis: (x: 0, y: 1, z: 0))
                                .scaleEffect(isScaleAnimation ? 2 : 1 )
                                .id(playerManager.currentTrack?.title ?? "")
                                .onAppear {
                                    if isFromCoverFlow {
                                        withAnimation(.snappy(duration: 0.6)) {
                                            isScaleAnimation = false
                                            currentDegree = 5
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                currentOpacity = 1
                                            }
                                        }
                                    } else {
                                        isScaleAnimation = false
                                        currentDegree = 5
                                        currentOpacity = 1
                                    }
                                }
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 150, height: 150)
                    
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
                    .id(playerManager.currentTrack?.title ?? "")
                    .padding(.horizontal, -4)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .background(Color.white)
        .frame(maxHeight: .infinity)
        .onAppear {
            iPlayrController.activePage = .player
            setupButtonListener()
            Task {
                if isFromPlaylist {
                    try await playerManager.playPlaylist(id: id, fromIndex: trackIndex)
                } else {
                    try await playerManager.playAlbum(id: id, fromIndex: trackIndex)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func setupButtonListener() {
        guard iPlayrController.activePage == .player else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu:
                    if !isFromCoverFlow {
                        dismiss()
                    }
                case .select:
                    break
                case .forwardEndAlt:
                    Task {
                        do {
                            await MainActor.run {
                                // UI güncellemelerini durdur
                                playerManager.isPlaying = false
                            }
                            try await playerManager.skipToNextTrack()
                            // Yeni şarkının yüklenmesini bekle
                            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
                            await MainActor.run {
                                playerManager.isPlaying = true
                            }
                        } catch {
                            print("Error skipping track: \(error)")
                        }
                    }
                case .backwardEndAlt:
                    Task {
                        do {
                            await MainActor.run {
                                playerManager.isPlaying = false
                            }
                            try await playerManager.skipToPreviousTrack()
                            try await Task.sleep(nanoseconds: 500_000_000)
                            await MainActor.run {
                                playerManager.isPlaying = true
                            }
                        } catch {
                            print("Error skipping track: \(error)")
                        }
                    }
                case .playPause:
                    Task {
                        try? await playerManager.togglePlayPause()
                    }
                }
            }
            .store(in: &cancellables)
    }
}

struct SongProgressView: View {
    @State var progress: Double = 0
    @EnvironmentObject private var playerManager: AppleMusicManager
    @State private var visualProgress: Double = 0
    @State private var timer: Timer?
    
    private var currentDuration: TimeInterval {
        playerManager.currentTrack?.duration ?? 0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(formattedTime(from: Int(visualProgress * currentDuration)))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 50)
                .multilineTextAlignment(.trailing)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.white).gradient.shadow(.inner(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)))
                        .frame(height: 18)
                    Rectangle()
                        .fill(Color(.white).gradient.shadow(.inner(color: .black.opacity(0.2), radius: 10, x: 0, y: 2)))
                        .frame(height: 18)
                    Rectangle()
                        .fill(Color(.systemBlue).gradient.shadow(.inner(color: .white.opacity(0.2), radius: 8, x: 0, y: -4)))
                        .frame(width: geo.size.width * CGFloat(visualProgress), height: 18)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 18)
            .padding(8)
            
            Text("-\(formattedTime(from: Int(currentDuration - (visualProgress * currentDuration))))")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 50)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity)
        .onAppear(perform: startVisualTimer)
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: currentDuration) { oldValue, newValue in
            if abs(oldValue - newValue) > 1 {
                progress = 0
                visualProgress = 0
                startVisualTimer()
            }
        }
        .onChange(of: playerManager.isPlaying) { _, isPlaying in
            if isPlaying {
                startVisualTimer()
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
        .onChange(of: playerManager.currentTrack?.title) { _, _ in
            progress = 0
            visualProgress = 0
            timer?.invalidate()
            timer = nil
            if playerManager.isPlaying {
                startVisualTimer()
            }
        }
    }
    
    @MainActor private func startVisualTimer() {
        timer?.invalidate()
        timer = nil
        
        guard currentDuration > 0 else { return }
        let increment = 1.0 / currentDuration
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in            
            Task { @MainActor in
                if self.visualProgress < 1.0 && self.playerManager.isPlaying {
                    self.visualProgress = min(1.0, self.visualProgress + increment)
                }
            }
        }
    }
    
    private func formattedTime(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
