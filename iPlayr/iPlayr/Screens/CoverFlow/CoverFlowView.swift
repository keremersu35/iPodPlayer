import SwiftUI
import MusicKit
import Combine

struct CoverFlowView: View {
    @EnvironmentObject var iPlayrController: iPlayrButtonController
    @StateObject private var albumManager = AlbumManager()
    @Environment(\.dismiss) private var dismiss
    @State private var cancellables = Set<AnyCancellable>()
    @State private var albums: MusicItemCollection<Album> = []
    @State private var selectedIndex = 0
    @State private var selectedTrackIndex = 0
    @State private var viewState: ViewState = .loading
    @State private var isPlayerView = false
    @State private var isSongList = false
    @State private var playerViewId = UUID()

    @State private var scrollOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0

    private let itemWidth: CGFloat = 160
    private let spacing: CGFloat = 20
    private static let snapAnimation = Animation.spring(response: 0.35, dampingFraction: 0.85)
    private var itemStep: CGFloat { itemWidth + spacing }

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(title: isPlayerView ? "Now Playing" : "Cover Flow")

            ZStack {
                if viewState == .content {
                    contentView
                }

                if isPlayerView {
                    PlayerView(
                        id: albumManager.savedAlbums?[selectedIndex].id.rawValue ?? "",
                        trackIndex: selectedTrackIndex,
                        isFromCoverFlow: true,
                        isFromPlaylist: false,
                        initialArtwork: albums[selectedIndex].artwork
                    )
                    .id(playerViewId)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(2)
                }

                StateView(state: viewState)
            }
            .padding(.vertical, 16)
            .frame(maxHeight: .infinity)
            .background(Color.white)
        }
        .navigationBarBackButtonHidden()
        .task { await loadAlbums() }
        .onAppear(perform: setup)
        .onDisappear(perform: cleanup)
        .onChange(of: iPlayrController.selectedIndex) { _, newIndex in
            guard iPlayrController.activePage == .coverFlow else { return }
            navigateTo(newIndex, updateController: false)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if !isPlayerView {
            // Carousel — sits above albumInfo in zIndex when flipped
            VStack(spacing: 0) {
                Spacer().frame(height: 8)
                GeometryReader { geometry in
                    ZStack {
                        ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                            let relativeOffset = (CGFloat(index) * itemStep + scrollOffset + dragOffset) / itemStep

                            AlbumCover(
                                album: album,
                                isSelected: index == selectedIndex,
                                isSongList: $isSongList
                            )
                            .frame(width: itemWidth, height: itemWidth)
                            .rotation3DEffect(
                                .degrees(calculateRotation(offset: relativeOffset)),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.5
                            )
                            .scaleEffect(calculateScale(offset: relativeOffset))
                            .offset(x: calculateXOffset(offset: relativeOffset))
                            .zIndex(isSongList && index == selectedIndex ? 1000 : calculateZIndex(offset: relativeOffset))
                        }
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { dragOffset = $0.translation.width }
                        .onEnded { value in
                            let velocity = value.predictedEndTranslation.width
                            let targetOffset = scrollOffset + value.translation.width + (velocity / 2)
                            let index = Int(max(0, min(CGFloat(albums.count - 1), round(-targetOffset / itemStep))))
                            navigateTo(index)
                        }
                )

                Spacer().frame(height: 35)
            }
            .zIndex(isSongList ? 2 : 0)

            // Album info — floats to bottom via Spacer
            if !albums.isEmpty {
                albumInfo
            }
        }
    }

    private var albumInfo: some View {
        VStack(spacing: 2) {
            Spacer()

            Text(albums[selectedIndex].title)
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .lineLimit(2)

            Text(albums[selectedIndex].artistName)
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .zIndex(1)
        .animation(Self.snapAnimation, value: selectedIndex)
    }

    // MARK: - Navigation

    private func navigateTo(_ index: Int, updateController: Bool = true) {
        selectedIndex = index
        if updateController { iPlayrController.selectedIndex = index }
        withAnimation(Self.snapAnimation) {
            scrollOffset = -CGFloat(index) * itemStep
            dragOffset = 0
        }
    }

    // MARK: - Coverflow Math

    private func calculateRotation(offset: CGFloat) -> Double {
        let threshold: CGFloat = 0.2
        if offset > threshold { return -55 }
        if offset < -threshold { return 55 }
        return -Double(offset / threshold) * 55
    }

    private func calculateScale(offset: CGFloat) -> CGFloat {
        return max(1.0 - abs(offset) * 0.15, 0.8)
    }

    private func calculateXOffset(offset: CGFloat) -> CGFloat {
        if offset > 0.1 { return offset * 30 + 55 }
        if offset < -0.1 { return offset * 30 - 55 }
        return offset * 550
    }

    private func calculateZIndex(offset: CGFloat) -> Double {
        return (2.0 - abs(Double(offset))) * 10
    }

    // MARK: - Data

    private func loadAlbums() async {
        viewState = .loading
        await albumManager.getCurrentUserSavedAlbums()

        guard let savedAlbums = albumManager.savedAlbums else {
            viewState = .error(message: albumManager.errorMessage ?? "An error occurred\nPlease try again")
            return
        }

        if savedAlbums.isEmpty {
            viewState = .empty(message: "No albums found\nAdd some albums to your library")
        } else {
            albums = savedAlbums
            iPlayrController.menuCount = albums.count
            navigateTo(max(0, albums.count / 2))
            viewState = .content
        }
    }

    // MARK: - Setup / Teardown

    private func setup() {
        configureController()
        setupButtonListener()
        iPlayrController.setRightView(false)
    }

    private func configureController() {
        iPlayrController.activePage = .coverFlow
        iPlayrController.menuCount = albums.count
        iPlayrController.selectedIndex = selectedIndex
    }

    private func setupButtonListener() {
        iPlayrController.takeControl { action in
            handleButtonAction(action)
        }
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:   handleMenuAction()
        case .select: handleSelectAction()
        default: break
        }
    }

    private func handleMenuAction() {
        if isPlayerView {
            resetToMain()
        } else if isSongList {
            resetToCarousel()
        } else {
            dismiss()
        }
    }

    private func handleSelectAction() {
        if isSongList && iPlayrController.activePage == .coverFlowSongList {
            showPlayer()
        } else if !isSongList && !isPlayerView {
            showSongList()
        }
    }

    private func resetToMain() {
        isPlayerView = false
        isSongList = false
        selectedTrackIndex = 0
        configureController()
    }

    private func resetToCarousel() {
        isSongList = false
        configureController()
    }

    private func showPlayer() {
        playerViewId = UUID()
        selectedTrackIndex = iPlayrController.selectedIndex
        isPlayerView = true
    }

    private func showSongList() {
        isSongList = true
        iPlayrController.activePage = .coverFlowSongList
        iPlayrController.selectedIndex = 0
    }

    private func cleanup() {
        iPlayrController.setRightView(true)
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

// MARK: - Album Cover (with flip animation)

struct AlbumCover: View {
    let album: Album
    let isSelected: Bool
    @Binding var isSongList: Bool
    @State private var isFaceUp = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                albumArtwork
                songListOverlay
            }
            .frame(width: isFaceUp ? 300 : 160, height: isFaceUp ? 300 : 160)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onChange(of: isSongList) { _, newValue in
                if isSelected {
                    withAnimation(.linear(duration: 0.3)) {
                        isFaceUp = newValue
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private var albumArtwork: some View {
        Group {
            if let artwork = album.artwork {
                ArtworkImage(artwork, width: 160, height: 160)
            } else {
                Image(ImageNames.Custom.coverPlaceholder)
                    .resizable()
                    .frame(width: 160, height: 160)
            }
        }
        .modifier(FlipOpacity(pct: isFaceUp ? 0 : 1))
        .aspectRatio(contentMode: .fit)
        .rotation3DEffect(.degrees(isFaceUp ? 180 : 360), axis: (0, 1, 0))
        .reflection()
    }

    private var songListOverlay: some View {
        SongListView(album: album, isSelected: isSelected, isSongList: $isSongList)
            .frame(width: 300, height: 280)
            .background(Color.white)
            .border(.gray)
            .offset(y: 40)
            .modifier(FlipOpacity(pct: isFaceUp ? 1 : 0))
            .rotation3DEffect(.degrees(isFaceUp ? 0 : 180), axis: (0, 1, 0))
            .scaleEffect(isFaceUp ? 1 : 160 / 300)
            .zIndex(2)
    }
}
