import SwiftUI
import MusicKit

struct AlbumsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var libraryStore: MusicLibraryStore
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 0
    @State private var viewState: ViewState = .loading

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "Albums")

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
        .onDisappear {
            iPlayrController.saveCurrentIndex()
        }
    }

    private func loadAlbums() async {
        viewState = .loading
        await libraryStore.loadAlbumsIfNeeded()

        if let albums = libraryStore.albums {
            if albums.isEmpty {
                viewState = .empty(message: "No albums found\nAdd some albums to your library")
            } else {
                iPlayrController.menuCount = albums.count
                viewState = .content
            }
        } else {
            viewState = .error(message: libraryStore.errorMessage ?? "An error occurred\nPlease try again")
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
                .onChange(of: iPlayrController.selectedIndex) { _, newIndex in
                    guard iPlayrController.activePage == .albums else { return }
                    selectedIndex = newIndex
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
            isSelected: index == selectedIndex
        )
    }

    private func setup() {
        iPlayrController.setActivePage(.albums, menuCount: libraryStore.albums?.count ?? 0)
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
        guard let savedAlbums = libraryStore.albums, selectedIndex < savedAlbums.count else { return }
        let id = savedAlbums[selectedIndex].id
        let albumName = savedAlbums[selectedIndex].title
        navigate(.push(.albumTracks(id: id.rawValue, albumName: albumName)))
    }
}
