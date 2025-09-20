import SwiftUI
import MusicKit
import Combine

struct PlaylistTracksView: View {
    let collectionInfo: CollectionInfoModel
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @StateObject private var playlistManager = PlaylistManager()
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
        await playlistManager.getPlaylistTracks(collectionInfo.id)
        
        if let tracks = playlistManager.tracks {
            if tracks.isEmpty {
                viewState = .empty(message: "No tracks found in this playlist\nAdd some tracks to get started")
            } else {
                iPlayrController.menuCount = tracks.count
                viewState = .content
            }
        } else {
            viewState = .error(message: playlistManager.errorMessage ?? "An error occurred\nPlease try again later")
        }
    }
    
    @ViewBuilder
    private var tracksScrollView: some View {
        ScrollViewReader { scrollViewProxy in
            let savedTracks = playlistManager.tracks?.compactMap { $0 } ?? []
            let indexedTracks = Array(savedTracks.enumerated())
            List(indexedTracks, id: \.offset) { index, track in
                CollectionMenuItem(
                    model: track.toCollectionMenuModel(),
                    isSelected: index == selectedIndex
                )
                .id(index)
                .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
            .onChange(of: iPlayrController.selectedIndex) { _, newIndex in
                guard iPlayrController.activePage == .playlistTracks else { return }
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
    
    private func setup() {
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.activePage = .playlistTracks
        setupButtonListener()
    }
    
    private func setupButtonListener() {
        guard iPlayrController.activePage == .playlistTracks else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu:
                    dismiss()
                case .select:
                    let id = collectionInfo.id
                    navigate(.push(.player(id: id, trackIndex: selectedIndex, isFromPlaylist: true)))
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
