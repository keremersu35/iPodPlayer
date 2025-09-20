import SwiftUI
import Combine
import MusicKit

struct SongListView: View {
    let album: Album
    let isSelected: Bool
    @Binding var isSongList: Bool
    @EnvironmentObject var iPlayrController: iPlayrButtonController
    @StateObject private var albumManager = AlbumManager()
    @State private var cancellables = Set<AnyCancellable>()
    @State private var selectedIndex = 0
    @State private var isLoading = true
    private var shouldLoad: Bool { isSongList && isSelected }
    private var tracks: [Track] { albumManager.savedAlbumsTracks?.compactMap { $0 } ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                albumHeader
                tracksList
            }
            .opacity(isLoading ? 0 : 1)

            if isLoading {
                LoadingView()
            }
        }
        .onDisappear(perform: cleanup)
        .onChange(of: shouldLoad, initial: false) { _, shouldLoad in
            if shouldLoad { loadTracks() }
        }
        .onReceive(albumManager.$savedAlbumsTracks) { tracks in
            isLoading = tracks == nil
        }
    }

    private var albumHeader: some View {
        VStack(spacing: 0) {
            albumTitle
            artistName
        }
        .background(Color.songListBackground)
    }

    private var albumTitle: some View {
        Text(album.title)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.leading, 8)
            .lineLimit(1)
    }

    private var artistName: some View {
        Text(album.artistName)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
            .padding(.leading, 8)
            .lineLimit(1)
    }

    private var tracksList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
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
                    proxy.scrollTo(newIndex)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(selectedIndex)
                    }
                }
            }
            .padding(.bottom, 26)
        }
    }

    private func loadTracks() {
        Task {
            await albumManager.getAlbumTracks(id: album.id.rawValue)
            await updateControllerIfNeeded()
            await MainActor.run { isLoading = false }
        }
    }

    private func updateControllerIfNeeded() async {
        await MainActor.run {
            guard iPlayrController.activePage == .coverFlowSongList else { return }
            iPlayrController.menuCount = tracks.count
        }
    }

    private func cleanup() {
        isLoading = true
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

