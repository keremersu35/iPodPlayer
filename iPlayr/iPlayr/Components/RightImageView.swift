import SwiftUI
import MusicKit
import Combine

struct RightImageView: View {
    @StateObject private var albumManager = AlbumManager()
    @State private var currentImageIndex = 0
    @State private var timerCancellable: AnyCancellable?
    @State private var panDirection: PanDirection = .right

    private let transitionDuration: Double = 2
    private let imageDuration: Double = 8

    var body: some View {
        ZStack {
            Color.blue.opacity(0.3)
                .ignoresSafeArea()

            if MusicAuthorization.currentStatus != .authorized {
                unauthorizedView
            } else if let images = albumManager.savedAlbums?.compactMap({ $0.artwork }),
                      !images.isEmpty {
                artworkSlideshow(images)
            } else {
                noMusicView
            }
        }
        .task { await albumManager.getCurrentUserSavedAlbums() }
        .onReceive(albumManager.$savedAlbums) { albums in
            guard !(albums?.isEmpty ?? true) else { return }
            startImageCycle()
        }
        .onDisappear(perform: stopImageCycle)
    }

    private var unauthorizedView: some View {
        VStack {
            Image(systemName: "applelogo")
                .resizable()
                .frame(width: 60, height: 60)
            Spacer().frame(height: 16)
            Text("Please sign in to Apple Music")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
        }
    }

    private func artworkSlideshow(_ images: [Artwork]) -> some View {
        ZStack {
            if currentImageIndex >= 0 && currentImageIndex < images.count {
                ArtworkImage(images[currentImageIndex], width: 300, height: 300)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .modifier(PanEffect(
                        duration: imageDuration + transitionDuration,
                        direction: panDirection
                    ))
                    .id("\(currentImageIndex)-\(panDirection.rawValue)")
                    .transition(.opacity)
                    .animation(.easeInOut(duration: transitionDuration), value: currentImageIndex)
            }
        }
        .clipped()
    }

    private var noMusicView: some View {
        VStack {
            Image(systemName: ImageNames.System.musicNote)
                .resizable()
                .frame(width: 50, height: 90)
                .foregroundColor(.white)
            Spacer().frame(height: 16)
            Text("No Music")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .bold))
        }
    }

    private func startImageCycle() {
        stopImageCycle()
        timerCancellable = Timer.publish(every: imageDuration, on: .main, in: .common)
            .autoconnect()
            .sink { _ in transitionToNextImage() }
    }

    private func transitionToNextImage() {
        guard let albumsCount = albumManager.savedAlbums?.count,
              albumsCount > 1 else { return }

        withAnimation(.easeInOut(duration: transitionDuration)) {
            panDirection = panDirection == .right ? .left : .right
            currentImageIndex = (currentImageIndex + 1) % albumsCount
        }
    }

    private func stopImageCycle() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

enum PanDirection: String, CaseIterable {
    case left
    case right
}

struct PanEffect: ViewModifier {
    let duration: Double
    let direction: PanDirection
    @State private var offset: CGFloat = 0

    private var startOffset: CGFloat {
        switch direction {
        case .right: return -90
        case .left: return -30
        }
    }

    private var endOffset: CGFloat {
        switch direction {
        case .right: return -60
        case .left: return -60
        }
    }

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onAppear {
                offset = startOffset
                withAnimation(.linear(duration: duration)) {
                    offset = endOffset
                }
            }
            .onChange(of: direction) {
                offset = startOffset
                withAnimation(.linear(duration: duration)) {
                    offset = endOffset
                }
            }
    }
}
