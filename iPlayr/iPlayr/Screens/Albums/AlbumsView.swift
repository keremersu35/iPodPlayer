import SwiftUI
import MusicKit

struct AlbumsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var libraryStore: MusicLibraryStore
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scope = FocusScope(id: "albums")
    @State private var viewState: ViewState = .loading

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Albums"))

            ZStack {
                if viewState == ViewState.content {
                    albumsScrollView
                }
                StateView(state: viewState)
            }
        }
        .shadowedBackground()
        .task { await loadAlbums() }
        .onAppear(perform: setup)
        .navigationBarBackButtonHidden()
    }

    private func loadAlbums() async {
        viewState = .loading
        await libraryStore.loadAlbumsIfNeeded()

        if let albums = libraryStore.albums {
            if albums.isEmpty {
                viewState = .empty(message: String(localized: "No albums found\nAdd some albums to your library"))
            } else {
                scope.configure(itemCount: albums.count)
                viewState = .content
            }
        } else {
            viewState = .error(message: libraryStore.errorMessage ?? String(localized: "An error occurred\nPlease try again"))
        }
    }

    @ViewBuilder
    private var albumsScrollView: some View {
        ScrollViewReader { scrollViewProxy in
            if let savedAlbums = libraryStore.albums {
                List(savedAlbums.indices, id: \.self) { index in
                    let album = savedAlbums[index]
                    albumRow(for: album, index: index)
                        .id(index)
                        .listRowInsets(EdgeInsets())
                }
                .listStyle(.plain)
                .onChange(of: scope.selection) { _, newIndex in
                    scrollViewProxy.scrollTo(newIndex)
                }
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func albumRow(for album: Album, index: Int) -> some View {
        CollectionMenuItem(
            model: album.toCollectionMenuModel(),
            isSelected: index == scope.selection
        )
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
        guard let savedAlbums = libraryStore.albums, scope.selection < savedAlbums.count else { return }
        let id = savedAlbums[scope.selection].id
        let albumName = savedAlbums[scope.selection].title
        navigate(.push(.albumTracks(id: id.rawValue, albumName: albumName)))
    }
}
