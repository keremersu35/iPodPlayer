import SwiftUI
import MusicKit
import UIKit
import Combine

struct CoverFlowView: View {
    @EnvironmentObject var iPlayrController: iPlayrButtonController
    @StateObject private var albumManager = AlbumManager()
    @Environment(\.dismiss) private var dismiss
    @State private var cancellables = Set<AnyCancellable>()
    @State private var albums: MusicItemCollection<Album> = []
    @State private var selectedTrack: Album?
    @State private var selectedIndex = 0
    @State private var selectedTrackIndex = 0
    @State private var viewState: ViewState = .loading
    @State private var isPlayerView = false
    @State private var isSongList = false

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
                        isFromPlaylist: false
                    )
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
            selectedIndex = newIndex
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if !isPlayerView {
            VStack {
                CarouselWrapper(
                    albums: $albums,
                    selectedIndex: $selectedIndex,
                    isSongList: $isSongList
                )
                .frame(maxWidth: .infinity, maxHeight: 200)

                Spacer().frame(height: 35)
            }
            .zIndex(isSongList ? 2 : 0)

            if !albums.isEmpty {
                albumInfo
            }
        }
    }

    @ViewBuilder
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
    }

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
            selectedIndex = max(0, albums.count / 2)
            iPlayrController.selectedIndex = selectedIndex
            viewState = .content
        }
    }

    private func setup() {
        configureController()
        setupButtonListener()
    }

    private func configureController() {
        iPlayrController.activePage = .coverFlow
        iPlayrController.menuCount = albums.count
        iPlayrController.selectedIndex = selectedIndex
    }

    private func setupButtonListener() {
        iPlayrController.buttonPressed
            .sink { action in
                handleButtonAction(action)
            }
            .store(in: &cancellables)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            handleMenuAction()
        case .select:
            handleSelectAction()
        default:
            break
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
        selectedTrack = nil
        selectedTrackIndex = 0
        configureController()
    }

    private func resetToCarousel() {
        isSongList = false
        configureController()
    }

    private func showPlayer() {
        selectedTrack = albums[selectedIndex]
        selectedTrackIndex = iPlayrController.selectedIndex
        isPlayerView = true
    }

    private func showSongList() {
        isSongList = true
        iPlayrController.activePage = .coverFlowSongList
        iPlayrController.selectedIndex = 0
    }

    private func cleanup() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

struct CarouselWrapper: UIViewControllerRepresentable {
    @Binding var albums: MusicItemCollection<Album>
    @Binding var selectedIndex: Int
    @Binding var isSongList: Bool

    func makeUIViewController(context: Context) -> CarouselViewController {
        CarouselViewController(
            albums: albums,
            isSongList: $isSongList,
            selectedIndex: $selectedIndex
        )
    }

    func updateUIViewController(_ uiViewController: CarouselViewController, context: Context) {
        uiViewController.updateData(albums)
        uiViewController.animateToIndex(selectedIndex)
    }
}

final class CarouselViewController: UIViewController {
    private var albums: MusicItemCollection<Album>
    private var carousel: iCarousel!
    private let isSongList: Binding<Bool>
    private let selectedIndex: Binding<Int>

    init(albums: MusicItemCollection<Album>, isSongList: Binding<Bool>, selectedIndex: Binding<Int>) {
        self.albums = albums
        self.isSongList = isSongList
        self.selectedIndex = selectedIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCarousel()
        setupLayout()
    }

    private func setupCarousel() {
        carousel = iCarousel()
        carousel.animator = iCarousel.Animator.CoverFlow(isCoverFlow2: false)
            .wrapEnabled(false)
            .offsetMultiplier(1)
            .spacing(0.2)

        carousel.isScrollEnabled = false
        carousel.isPagingEnabled = true
        carousel.decelerationRate = 0.7
        carousel.itemWidth = 160
        carousel.delegate = self
        carousel.dataSource = self
    }

    private func setupLayout() {
        view.addSubview(carousel)
        carousel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            carousel.topAnchor.constraint(equalTo: view.topAnchor),
            carousel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carousel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carousel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func updateData(_ newAlbums: MusicItemCollection<Album>) {
        guard albums != newAlbums else { return }
        albums = newAlbums
        carousel.reloadData()
    }

    func animateToIndex(_ index: Int) {
        let targetOffset = CGFloat(index)
        let currentOffset = carousel.scrollOffset

        guard abs(currentOffset - targetOffset) > 0.01 else { return }

        carousel.layer.removeAllAnimations()
        let distance = abs(targetOffset - currentOffset)
        let (duration, options) = animationParameters(for: distance)

        if duration > 0 {
            UIView.animate(withDuration: duration, delay: 0, options: options) {
                self.carousel.scrollOffset = targetOffset
            } completion: { finished in
                if finished { self.carousel.reloadData() }
            }
        } else {
            carousel.scrollOffset = targetOffset
            carousel.reloadData()
        }
    }

    private func animationParameters(for distance: CGFloat) -> (TimeInterval, UIView.AnimationOptions) {
        switch distance {
        case 0...1: return (0.2, [.curveEaseInOut, .allowUserInteraction])
        case 1...3: return (0.10, [.curveEaseOut, .allowUserInteraction])
        case 3...5: return (0.05, [.curveEaseOut, .allowUserInteraction])
        default: return (0, [])
        }
    }
}

extension CarouselViewController: iCarouselDelegate, @preconcurrency iCarouselDataSource {
    func numberOfItems() -> Int { albums.count }

    func carousel(viewForItemAt index: Int) -> UIView {
        let album = albums[index]
        let isSelected = album.id == albums[selectedIndex.wrappedValue].id

        let albumCoverView = AlbumCover(
            album: album,
            isSelected: isSelected,
            isSongList: isSongList
        )

        let hostingController = UIHostingController(rootView: albumCoverView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 160, height: 160)
        hostingController.view.backgroundColor = .clear
        return hostingController.view
    }
}

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
        .zIndex(isFaceUp ? 1000 : 0)
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
