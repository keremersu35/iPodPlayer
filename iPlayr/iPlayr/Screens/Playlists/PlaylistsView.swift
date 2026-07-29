import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var libraryStore: MusicLibraryStore
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scope = FocusScope(id: "playlists")
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
    }

    private func loadPlaylists() async {
        viewState = .loading
        await libraryStore.loadPlaylistsIfNeeded()

        if let playlists = libraryStore.playlists {
            if playlists.isEmpty {
                viewState = .empty(message: "No playlists found\nCreate some playlists to get started")
            } else {
                scope.configure(itemCount: playlists.count)
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
                    isSelected: index == scope.selection
                )
                .id(index)
                .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
            .onChange(of: scope.selection) { _, newIndex in
                scrollViewProxy.scrollTo(newIndex)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollViewProxy.scrollTo(scope.selection)
                }
            }
        }
    }

    private func setup() {
        scope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu: dismiss()
        case .select: navigation()
        default: break
        }
    }

    private func navigation() {
        guard let playlists = libraryStore.playlists, scope.selection < playlists.count else { return }
        let id = playlists[scope.selection].id
        let playlistName = playlists[scope.selection].name
        navigate(.push(.playlistTracks(id: id.rawValue, playlistName: playlistName)))
    }

}
