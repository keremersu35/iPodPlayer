import SwiftUI
import Combine
import Equatable

@Equatable
struct PlaylistsView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @StateObject private var playlistManager = PlaylistManager()
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 0
    @State private var cancellables = Set<AnyCancellable>()
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
        .onDisappear(perform: cancelSubscriptions)
    }
    
    private func loadPlaylists() async {
        viewState = .loading
        await playlistManager.fetchPlaylists()
        
        if let playlists = playlistManager.playlists {
            if playlists.isEmpty {
                viewState = .empty(message: "No playlists found\nCreate some playlists to get started")
            } else {
                iPlayrController.menuCount = playlists.count
                viewState = .content
            }
        } else {
            viewState = .error(message: playlistManager.errorMessage ?? "An error occurred\nPlease try again later")
        }
    }
    
    @ViewBuilder
    private var playlistScrollView: some View {
        ScrollViewReader { scrollViewProxy in
            let savedPlaylists = playlistManager.playlists?.compactMap { $0 } ?? []
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
        iPlayrController.selectedIndex = selectedIndex
        iPlayrController.activePage = .playlists
        iPlayrController.hasRightView = false
        setupButtonListener()
    }
    
    private func setupButtonListener() {
        guard iPlayrController.activePage == .playlists else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu: dismiss()
                case .select:
                    let id = playlistManager.playlists?[selectedIndex].id ?? ""
                    let playlistName = playlistManager.playlists?[selectedIndex].name ?? ""
                    navigate(.push(.playlistTracks(id: id.rawValue, playlistName: playlistName)))
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
