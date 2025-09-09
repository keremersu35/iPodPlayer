import SwiftUI
import Combine
import MusicKit
import Equatable

@Equatable
struct SongListView: View {
    let album: Album
    @EnvironmentObject var iPlayrController: iPlayrButtonController
    @StateObject private var albumManager = AlbumManager()
    @State private var cancellables = Set<AnyCancellable>()
    @Binding var isFaceUp: Bool
    @State private var selectedIndex : Int = 0
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                LoadingView()
            } else {
                VStack {
                    Text(album.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                        .padding(.leading, 8)
                        .lineLimit(1)
                    
                    Text(album.artistName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                        .padding(.leading, 8)
                        .lineLimit(1)
                }
                .background(Color.songListBackground)

                tracksScrollView
                    .padding(.bottom, 26)
            }
        }
        .onAppear(perform: setup)
        .onDisappear(perform: cancelSubscriptions)
        .task { await albumManager.getAlbumTracks(id: album.id.rawValue) }
        .onReceive(albumManager.$savedAlbumsTracks) { tracks in
            iPlayrController.menuCount = tracks?.count ?? 0
            isLoading = tracks == nil
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
                    guard iPlayrController.activePage == .coverFlowSongList else { return }
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
        iPlayrController.activePage = .coverFlowSongList
        setupButtonListener()
        iPlayrController.hasRightView = false
    }
    
    private func setupButtonListener() {
        guard iPlayrController.activePage == .coverFlowSongList else { return }
        iPlayrController.buttonPressed
            .sink { action in
                switch action {
                case .menu:
                    withAnimation(.linear(duration: 0.2)) {
                        isFaceUp = false
                    }
                case .select: break
                default: break
                }
            }
            .store(in: &cancellables)
    }
    
    private func cancelSubscriptions() {
        isLoading = true
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
