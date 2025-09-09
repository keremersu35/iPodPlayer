import SwiftUI
import Combine
import MusicKit
import Equatable

@Equatable
struct RightImageView: View {
    @StateObject private var albumManager = AlbumManager()
    @State private var currentImageIndex = 0
    @State private var nextImageIndex = 1
    @State private var timerCancellable: AnyCancellable?
    @State private var opacity = 0.0
    @State private var offset = -120.0
    
    private let transitionDuration: Double = 3
    private let imageDuration: Double = 8
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.3)
            
            if MusicAuthorization.currentStatus != .authorized {
                unauthorizedView
            } else if let images = albumManager.savedAlbums?.compactMap({ $0.artwork }), !images.isEmpty {
                artworkView(images)
            } else {
                noMusicView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await albumManager.getCurrentUserSavedAlbums() }
        .onReceive(albumManager.$savedAlbums) { albums in
            guard !(albums?.isEmpty ?? true) else { return }
            startImageCycle()
        }
        .onDisappear(perform: stopImageCycle)
    }

    private var unauthorizedView: some View {
        VStack {
            Image(ImageNames.Custom.appleMusic)
                .resizable()
                .frame(width: 60, height: 60)
            Spacer().frame(height: 16)
            Text("Please sign in to Apple Music")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
        }
    }

    private func artworkView(_ images: [Artwork]) -> some View {
        ZStack {
            ArtworkImage(images[currentImageIndex], width: 300, height: 300)
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: offset)
                .clipped()
                .onAppear {
                    withAnimation(.linear(duration: imageDuration + 2)) {
                        offset = -90
                    }
                }
            
            if images.count > 1 {
                ArtworkImage(images[nextImageIndex], width: 300, height: 300)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: -120)
                    .clipped()
                    .opacity(opacity)
            }
        }
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
        guard let imagesCount = albumManager.savedAlbums?.count,
              imagesCount > 1 else { return }
        
        withAnimation(.easeInOut(duration: transitionDuration)) { opacity = 1.0 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
            currentImageIndex = nextImageIndex
            offset = -115
            nextImageIndex = (nextImageIndex + 1) % imagesCount
            opacity = 0.0
            withAnimation(.linear(duration: imageDuration + 2)) { offset = -90 }
        }
    }
    
    private func stopImageCycle() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
