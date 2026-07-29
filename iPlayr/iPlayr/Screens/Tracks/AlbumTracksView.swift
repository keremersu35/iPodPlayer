import SwiftUI
import MusicKit

struct AlbumTracksView: View {
    let collectionInfo: CollectionInfoModel
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var libraryStore: MusicLibraryStore
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 0
    @State private var viewState: ViewState = .loading
    @State private var tracks: [Track] = []

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
        .onDisappear {
            iPlayrController.saveCurrentIndex()
        }
    }
    
    private func loadTracks() async {
        viewState = .loading
        let fetchedTracks = await libraryStore.albumTracks(id: collectionInfo.id)

        if let fetchedTracks {
            tracks = fetchedTracks
            if fetchedTracks.isEmpty {
                viewState = .empty(message: "No tracks found in this album")
            } else {
                iPlayrController.menuCount = fetchedTracks.count
                viewState = .content
            }
        } else {
            viewState = .error(message: libraryStore.errorMessage ?? "An error occurred\nPlease try again later")
        }
    }

    @ViewBuilder
    private var tracksScrollView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    let indexedTracks = Array(tracks.enumerated())
                    
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
        iPlayrController.setActivePage(.albumTracks, menuCount: tracks.count)
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
        let id = collectionInfo.id
        navigate(.push(.player(id: id, trackIndex: selectedIndex)))
    }
    
}
