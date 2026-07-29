import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var libraryStore: MusicLibraryStore
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 0
    @State private var viewState: ViewState = .loading

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "Playlists")
            ZStack {
                if viewState == .content {
                    playlistScrollView
                }
                StateView(state: viewState)
            }
        }
        .shadowedBackground()
        .task { await loadPlaylists() }
        .onAppear(perform: setup)
        .navigationBarBackButtonHidden()
        .onDisappear {
            iPlayrController.saveCurrentIndex()
        }
    }
    
    private func loadPlaylists() async {
        viewState = .loading
        await libraryStore.loadPlaylistsIfNeeded()

        if let playlists = libraryStore.playlists {
            if playlists.isEmpty {
                viewState = .empty(message: "No playlists found\nCreate some playlists to get started")
            } else {
                iPlayrController.menuCount = playlists.count
                viewState = .content
            }
        } else {
            viewState = .error(message: libraryStore.errorMessage ?? "An error occurred\nPlease try again later")
        }
    }

    @ViewBuilder
    private var playlistScrollView: some View {
        ScrollViewReader { scrollViewProxy in
            let savedPlaylists = libraryStore.playlists ?? []
            let indexedPlaylists = Array(savedPlaylists.enumerated())
            List(indexedPlaylists, id: \.offset) { index, playlist in
                CollectionMenuItem(
                    model: playlist.toCollectionMenuModel(),
                    isSelected: index == selectedIndex
                )
                .id(index)
                .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
            .onChange(of: iPlayrController.selectedIndex) { _, newIndex in
                guard iPlayrController.activePage == .playlists else { return }
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
        iPlayrController.setActivePage(.playlists, menuCount: libraryStore.playlists?.count ?? 0)
        selectedIndex = iPlayrController.selectedIndex
        
        iPlayrController.takeControl { action in
            handleButtonAction(action)
        }
    }
    
    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu: dismiss()
        case .select: navigation()
        default: break
        }
    }
    
    private func navigation() {
        iPlayrController.releaseControl()
        guard let playlists = libraryStore.playlists, selectedIndex < playlists.count else { return }
        let id = playlists[selectedIndex].id
        let playlistName = playlists[selectedIndex].name
        navigate(.push(.playlistTracks(id: id.rawValue, playlistName: playlistName)))
    }
    
}
