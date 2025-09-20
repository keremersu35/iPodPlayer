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
    @State private var selectedTrackIndex: Int = 0
    @State private var viewState: ViewState = .loading
    @State private var isPlayerView = false
    @State private var isSongList: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(title: isPlayerView ? "Now Playing" : "CoverFlow")
            ZStack {
                if viewState == .content {
                    if !isPlayerView {
                        VStack {
                            CarouselViewControllerWrapper(
                                dataSource: $albums,
                                selectedIndex: $selectedIndex,
                                isSongList: $isSongList
                            )
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            Spacer()
                                .frame(height: 35)
                        }
                        .frame(maxWidth: .infinity)
                        .zIndex(isSongList ? 2 : 0)

                        if !albums.isEmpty {
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
                    }
                }

                if isPlayerView {
                    PlayerView(
                        id: albumManager.savedAlbums?[selectedIndex].id.rawValue ?? "",
                        trackIndex: selectedTrackIndex,
                        isFromCoverFlow: true, isFromPlaylist: false
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(2)
                }

                StateView(state: viewState)
            }
            .padding(.vertical, 16)
            .frame(maxHeight: .infinity)
            .background(Color.white)
            .navigationBarBackButtonHidden()
            .task { await loadAlbums() }
            .onAppear(perform: setup)
            .onChange(of: iPlayrController.selectedIndex) { _, newIndex in
                guard iPlayrController.activePage == .coverFlow else { return }
                selectedIndex = newIndex
            }
            .onChange(of: isSongList) { oldValue, newValue in
                if oldValue, !newValue {
                    resetup()
                }
            }
        }
    }

    private func loadAlbums() async {
        viewState = .loading
        await albumManager.getCurrentUserSavedAlbums()

        if let savedAlbums = albumManager.savedAlbums {
            if savedAlbums.isEmpty {
                viewState = .empty(message: "No albums found\nAdd some albums to your library")
            } else {
                albums = savedAlbums
                iPlayrController.menuCount = albums.count
                viewState = .content
            }
        } else {
            viewState = .error(message: albumManager.errorMessage ?? "An error occurred\nPlease try again")
        }
    }
}

extension CoverFlowView {
    private func setup() {
        iPlayrController.hasRightView = false
        iPlayrController.activePage = .coverFlow
        iPlayrController.menuCount = albums.count
        iPlayrController.selectedIndex = selectedIndex
        setupButtonListener()
    }

    private func resetup() {
        iPlayrController.activePage = .coverFlow
        iPlayrController.menuCount = albums.count
        iPlayrController.selectedIndex = selectedIndex
    }

    private func setupButtonListener() {
        guard iPlayrController.activePage == .coverFlow, !isSongList, !isPlayerView else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu:
                    if isSongList {
                        withAnimation(.spring(duration: 0.2)) {
                            isSongList = false
                        }
                    } else if isPlayerView {
                        isPlayerView = false
                    } else {
                        dismiss()
                    }
                case .select:
                    if isSongList && (iPlayrController.activePage == .coverFlow || iPlayrController.activePage == .coverFlowSongList) {
                        selectedTrackIndex = iPlayrController.selectedIndex
                        selectedTrack = albums[selectedIndex]
                        isPlayerView = true
                    } else {
                        isSongList = true
                    }
                default: break
                }
            }
            .store(in: &cancellables)
    }

    private func cancelSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

struct CarouselViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var dataSource: MusicItemCollection<Album>
    @Binding var selectedIndex: Int
    @Binding var isSongList: Bool

    func makeUIViewController(context: Context) -> CarouselViewController {
        let viewController = CarouselViewController(isSongList: $isSongList, selectedIndex: $selectedIndex)
        viewController.dataSource = dataSource
        return viewController
    }

    func updateUIViewController(_ uiViewController: CarouselViewController, context: Context) {
        if uiViewController.dataSource != dataSource {
            uiViewController.dataSource = dataSource
            uiViewController.carousel.reloadData()
        }

        let currentOffset = uiViewController.carousel.scrollOffset
        let targetOffset = CGFloat(selectedIndex)

        if abs(currentOffset - targetOffset) > 0.01 {
            uiViewController.carousel.layer.removeAllAnimations()

            let distance = abs(targetOffset - currentOffset)
            let (duration, animationOptions) = calculateAnimationParams(for: distance)

            if duration > 0 {
                UIView.animate(withDuration: duration, delay: 0, options: animationOptions, animations: {
                    uiViewController.carousel.scrollOffset = targetOffset
                }, completion: { finished in
                    if finished && abs(uiViewController.carousel.scrollOffset - targetOffset) < 0.1 {
                        Task {
                            await MainActor.run {
                                uiViewController.carousel.reloadData()
                            }
                        }
                    }
                })
            } else {
                uiViewController.carousel.scrollOffset = targetOffset
                Task {
                    await MainActor.run {
                        uiViewController.carousel.reloadData()
                    }
                }
            }
        }
    }

    private func calculateAnimationParams(for distance: CGFloat) -> (TimeInterval, UIView.AnimationOptions) {
        switch distance {
        case 0...1: return (0.2, [.curveEaseInOut, .allowUserInteraction])
        case 1...3: return (0.10, [.curveEaseOut, .allowUserInteraction])
        case 3...5: return (0.05, [.curveEaseOut, .allowUserInteraction])
        default: return (0, [])
        }
    }
}

final class CarouselViewController: UIViewController {
    var dataSource: MusicItemCollection<Album> = []
    var carousel: iCarousel!
    private var isSongList: Binding<Bool>
    private var selectedIndex: Binding<Int>

    init(isSongList: Binding<Bool>, selectedIndex: Binding<Int>) {
        self.isSongList = isSongList
        self.selectedIndex = selectedIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        carousel = iCarousel()
        carousel.translatesAutoresizingMaskIntoConstraints = false
        carousel.animator = iCarousel.Animator.CoverFlow(isCoverFlow2: false)
            .wrapEnabled(false)
            .offsetMultiplier(1)
            .spacing(0.2)
        carousel.isScrollEnabled = false
        carousel.isPagingEnabled = true
        carousel.decelerationRate = 0.7
        carousel.delegate = self
        carousel.itemWidth = 160
        carousel.dataSource = self
        setup()
    }

    private func setup() {
        view.addSubview(carousel)
        carousel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            carousel.topAnchor.constraint(equalTo: view.topAnchor),
            carousel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carousel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carousel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CarouselViewController: iCarouselDelegate, iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int { dataSource.count }

    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusingView: UIView?) -> UIView {
        let album = dataSource[index]
        let albumCoverView = AlbumCover(
            album: album,
            isSongList: isSongList,
            isSelected: album.id == dataSource[selectedIndex.wrappedValue].id
        )
        let hostingController = UIHostingController(rootView: albumCoverView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 160, height: 160)
        hostingController.view.backgroundColor = .clear
        return hostingController.view
    }
}

struct AlbumCover: View {
    let album: Album
    @State var isFaceUp: Bool = false
    @Binding var isSongList: Bool
    var isSelected: Bool

    var body: some View {
        GeometryReader { cardGeometry in
            ZStack {
                if let artwork = album.artwork {
                    ArtworkImage(artwork, width: 160, height: 160)
                        .modifier(FlipOpacity(pct: isFaceUp ? 0 : 1))
                        .aspectRatio(contentMode: .fit)
                        .rotation3DEffect(Angle.degrees(isFaceUp ? 180 : 360), axis: (0,1,0))
                        .reflection()
                } else {
                    Image(ImageNames.Custom.coverPlaceholder)
                        .resizable()
                        .frame(width: 160, height: 160)
                        .modifier(FlipOpacity(pct: isFaceUp ? 0 : 1))
                        .aspectRatio(contentMode: .fit)
                        .rotation3DEffect(Angle.degrees(isFaceUp ? 180 : 360), axis: (0,1,0))
                        .reflection()
                }

                if isFaceUp {
                    SongListView(album: album, isFaceUp: $isFaceUp)
                    .frame(width: 300, height: 280)
                    .background(Color.white)
                    .zIndex(2)
                    .border(.gray)
                    .offset(y: 40)
                    .modifier(FlipOpacity(pct: isFaceUp ? 1 : 0))
                    .rotation3DEffect(Angle.degrees(isFaceUp ? 0 : 180), axis: (0,1,0))
                    .scaleEffect(isFaceUp ? 1 : 160 / 300)
                    .onAppear { isSongList = true }
                    .onDisappear { isSongList = false }
                }
            }
            .frame(width: isFaceUp ? 300 : 160, height: isFaceUp ? 300 : 160)
            .position(x: cardGeometry.size.width/2,
                     y: cardGeometry.size.height/2)
            .onChange(of: isSongList) { _, newValue in
                if !newValue { resetState() } else {
                    if isSelected {
                        withAnimation(.linear(duration: 0.2)) {
                            isFaceUp.toggle()
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .zIndex(isFaceUp ? 1000 : 0)
    }

    private func resetState() {
        isFaceUp = false
    }
}
