import SwiftUI
import MusicKit

struct PlaylistTracksView: View {
    let collectionInfo: CollectionInfoModel
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @EnvironmentObject private var libraryStore: MusicLibraryStore
    @Environment(\.navigate) private var navigate
    @StateObject private var scope = FocusScope(id: "playlistTracks")
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
        .taskAfterPush { await loadTracks() }
    }

    private func loadTracks() async {
        viewState = .loading
        let fetchedTracks = await libraryStore.playlistTracks(id: collectionInfo.id)

        if let fetchedTracks {
            tracks = fetchedTracks
            if fetchedTracks.isEmpty {
                viewState = .empty(message: String(localized: "No tracks found in this playlist\nAdd some tracks to get started"))
            } else {
                scope.configure(itemCount: fetchedTracks.count)
                viewState = .content
            }
        } else {
            viewState = .error(message: libraryStore.errorMessage ?? String(localized: "An error occurred\nPlease try again later"))
        }
    }

    @ViewBuilder
    private var tracksScrollView: some View {
        ScrollViewReader { scrollViewProxy in
            let indexedTracks = Array(tracks.enumerated())
            List(indexedTracks, id: \.offset) { index, track in
                CollectionMenuItem(
                    model: track.toCollectionMenuModel(),
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
        case .menu:
            navigate(.pop)
        case .select:
            navigation()
        default:
            break
        }
    }

    private func navigation() {
        let id = collectionInfo.id
        navigate(.push(.player(id: id, trackIndex: scope.selection, isFromPlaylist: true)))
    }
}
