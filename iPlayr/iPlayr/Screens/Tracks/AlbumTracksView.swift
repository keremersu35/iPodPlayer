import SwiftUI
import Combine
import MusicKit
import Equatable

@Equatable
struct AlbumTracksView: View {
    let collectionInfo: CollectionInfoModel
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @StateObject private var albumManager = AlbumManager()
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 0
    @State private var viewState: ViewState = .loading

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: collectionInfo.title)
            ZStack {
                if viewState == .content {
                    tracksScrollView
                }
                StateView(state: viewState)
            }
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .task { await loadTracks() }
        .navigationBarBackButtonHidden()
        .onDisappear(perform: cancelSubscriptions)
    }
    
    private func loadTracks() async {
        viewState = .loading
        await albumManager.getAlbumTracks(id: collectionInfo.id)
        
        if let tracks = albumManager.savedAlbumsTracks {
            if tracks.isEmpty {
                viewState = .empty(message: "No tracks found in this album")
            } else {
                iPlayrController.menuCount = tracks.count
                viewState = .content
            }
        } else {
            viewState = .error(message: albumManager.errorMessage ?? "An error occurred\nPlease try again later")
        }
    }
    
    @ViewBuilder
    private var tracksScrollView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                VStack(spacing: 0) {
                    let savedTracks = albumManager.savedAlbumsTracks?.compactMap { $0 } ?? []
                    let indexedTracks = Array(savedTracks.enumerated())
                    
                    ForEach(indexedTracks, id: \.offset) { index, track in
                        MenuItemView(
                            menu: Menu(id: index, name: track.title, next: selectedIndex == index),
                            isSelected: selectedIndex == index
                        )
                        .id(index)
                    }
                }
                .onChange(of: iPlayrController.selectedIndex) { _, newIndex in
                    guard iPlayrController.activePage == .albumTracks else { return }
                    selectedIndex = newIndex
                    scrollViewProxy.scrollTo(newIndex)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollViewProxy.scrollTo(selectedIndex)
                    }
                }
            }
        }
    }

    private func setup() {
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.activePage = .albumTracks
        iPlayrController.hasRightView = false
        setupButtonListener()
    }
    
    private func setupButtonListener() {
        guard iPlayrController.activePage == .albumTracks else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu:
                    dismiss()
                case .select:
                    let id = collectionInfo.id
                    navigate(.push(.player(id: id, trackIndex: selectedIndex)))
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func cancelSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
