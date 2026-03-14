import SwiftUI
import MusicKit
import Combine

struct AlbumsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @StateObject private var albumManager = AlbumManager()
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 0
    @State private var cancellables = Set<AnyCancellable>()
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
            cancelSubscriptions()
        }
    }
    
    private func loadAlbums() async {
        viewState = .loading
        await albumManager.getCurrentUserSavedAlbums()
        
        if let albums = albumManager.savedAlbums {
            if albums.isEmpty {
                viewState = .empty(message: "No albums found\nAdd some albums to your library")
            } else {
                iPlayrController.menuCount = albums.count
                viewState = .content
            }
        } else {
            viewState = .error(message: albumManager.errorMessage ?? "An error occurred\nPlease try again")
        }
    }
    
    @ViewBuilder
    private var albumsScrollView: some View {
        ScrollViewReader { scrollViewProxy in
            if let savedAlbums = albumManager.savedAlbums {
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
                Text("No albums found")
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
        iPlayrController.setActivePage(.albums, menuCount: albumManager.savedAlbums?.count ?? 0)
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
        let id = albumManager.savedAlbums?[selectedIndex].id ?? ""
        let albumName = albumManager.savedAlbums?[selectedIndex].title ?? ""
        navigate(.push(.albumTracks(id: id.rawValue, albumName: albumName)))
    }
    
    private func cancelSubscriptions() {
        cancellables.cancelAll()
    }
}
