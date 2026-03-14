import SwiftUI
import MusicKit

struct CoverFlowView: View {
    @EnvironmentObject var iPlayrController: iPlayrButtonController
    @StateObject private var albumManager = AlbumManager()
    @State private var scrollAnimator = CoverFlowScrollAnimator()
    @Environment(\.dismiss) private var dismiss

    @State private var albums: MusicItemCollection<Album> = []
    @State private var selectedIndex = 0
    @State private var selectedTrackIndex = 0
    @State private var viewState: ViewState = .loading
    @State private var isPlayerView = false
    @State private var isSongList = false
    @State private var playerViewId = UUID()
    @State private var dragOffset: CGFloat = 0

    private let itemWidth: CGFloat = 160
    private let itemStep: CGFloat = 180
    private let tilt: CGFloat = 0.7
    private let cfSpacing: CGFloat = 0.2

    private var scrollOffset: CGFloat { scrollAnimator.scrollOffset }

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
                        initialArtwork: albums[selectedIndex].artwork,
                        onDismissFromCoverFlow: handleMenuAction
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
        .onChange(of: iPlayrController.selectedIndex) { _, newIndex in
            guard iPlayrController.activePage == .coverFlow else { return }
            navigateTo(newIndex, updateController: false)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if !isPlayerView {
            VStack(spacing: 0) {
                Spacer().frame(height: 8)
                GeometryReader { geometry in
                    ZStack {
                        ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                            let offset = relativeOffset(for: index)
                            AlbumCover(album: album, isSelected: index == selectedIndex, isSongList: $isSongList)
                                .frame(width: itemWidth, height: itemWidth)
                                .rotation3DEffect(.degrees(rotation(offset)), axis: (x: 0, y: 1, z: 0), perspective: 0.3)
                                .scaleEffect(scale(offset))
                                .offset(x: xOffset(offset))
                                .zIndex(isSongList && index == selectedIndex ? 1000 : zIndex(offset))
                        }
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .contentShape(Rectangle())
                .simultaneousGesture(dragGesture)

                Spacer().frame(height: 35)
            }
            .zIndex(isSongList ? 2 : 0)

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
                .lineLimit(1)
                .id("title-\(selectedIndex)")
                .transition(.opacity)
            Text(albums[selectedIndex].artistName)
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .lineLimit(1)
                .id("artist-\(selectedIndex)")
                .transition(.opacity)
        }
        .padding(.horizontal, 16)
        .zIndex(1)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { dragOffset = $0.translation.width }
            .onEnded { value in
                let projected = scrollOffset + value.translation.width + value.predictedEndTranslation.width / 2
                let index = Int(max(0, min(CGFloat(albums.count - 1), round(-projected / itemStep))))
                navigateTo(index)
            }
    }

    // MARK: - Navigation

    private func navigateTo(_ index: Int, updateController: Bool = true) {
        selectedIndex = index
        if updateController { iPlayrController.selectedIndex = index }
        scrollAnimator.jumpTo(scrollOffset + dragOffset)
        dragOffset = 0
        scrollAnimator.animateTo(-CGFloat(index) * itemStep)
    }

    // MARK: - Transform

    private func relativeOffset(for index: Int) -> CGFloat {
        (CGFloat(index) * itemStep + scrollOffset + dragOffset) / itemStep
    }

    private func rotation(_ offset: CGFloat) -> Double {
        -Double(max(-1, min(1, offset))) * 90 * Double(tilt)
    }

    private func xOffset(_ offset: CGFloat) -> CGFloat {
        let clamp = max(-1, min(1, offset))
        return (clamp * 0.5 * tilt + offset * cfSpacing) * itemWidth
    }

    private func scale(_ offset: CGFloat) -> CGFloat {
        max(1 - abs(max(-1, min(1, offset))) * 0.15, 0.85)
    }

    private func zIndex(_ offset: CGFloat) -> Double {
        (2 - abs(Double(offset))) * 10
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
            let initialIndex = max(0, albums.count / 2)
            selectedIndex = initialIndex
            iPlayrController.menuCount = albums.count
            iPlayrController.selectedIndex = initialIndex
            scrollAnimator.jumpTo(-CGFloat(initialIndex) * itemStep)
            viewState = .content
        }
    }

    // MARK: - Lifecycle

    private func setup() {
        iPlayrController.activePage = .coverFlow
        iPlayrController.menuCount = albums.count
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.takeControl { handleButtonAction($0) }
    }

    // MARK: - Button Actions

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:   handleMenuAction()
        case .select: handleSelectAction()
        default: break
        }
    }

    private func handleMenuAction() {
        if isPlayerView {
            isPlayerView = false
            isSongList = false
            selectedTrackIndex = 0
            configureController()
        } else if isSongList {
            isSongList = false
            configureController()
        } else {
            dismiss()
        }
    }

    private func handleSelectAction() {
        if isSongList && iPlayrController.activePage == .coverFlowSongList {
            let trackIndex = iPlayrController.selectedIndex
            // Wait for the flip animation to finish before loading PlayerView
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                playerViewId = UUID()
                selectedTrackIndex = trackIndex
                isPlayerView = true
            }
        } else if !isSongList && !isPlayerView {
            isSongList = true
            iPlayrController.activePage = .coverFlowSongList
            iPlayrController.selectedIndex = 0
        }
    }

    private func configureController() {
        iPlayrController.activePage = .coverFlow
        iPlayrController.menuCount = albums.count
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.takeControl { handleButtonAction($0) }
    }
}
