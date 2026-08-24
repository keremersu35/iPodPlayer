import SwiftUI
import UIKit

struct AboutView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "about")
    @State private var page = 0

    private var pages: [[Menu]] {
        [
            [
                Menu(name: String(localized: "Songs"), next: false, value: count(libraryStore.songs?.count)),
                Menu(name: String(localized: "Albums"), next: false, value: count(libraryStore.albums?.count)),
                Menu(name: String(localized: "Artists"), next: false, value: count(libraryStore.artists?.count)),
                Menu(name: String(localized: "Playlists"), next: false, value: count(libraryStore.playlists?.count)),
            ],
            [
                Menu(name: String(localized: "Genres"), next: false, value: count(libraryStore.genres?.count)),
                Menu(name: String(localized: "Composers"), next: false, value: count(libraryStore.composers?.count)),
            ],
            [
                Menu(name: String(localized: "Model"), next: false, value: deviceModel),
                Menu(name: String(localized: "Version"), next: false, value: appVersion),
            ],
        ]
    }

    private func count(_ value: Int?) -> String {
        guard let value else { return "—" }
        return String(value)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var deviceModel: String {
        UIDevice.current.model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "About"))
            let rows = pages[min(page, pages.count - 1)]
            ForEach(rows.indices, id: \.self) { index in
                MenuItemView(menu: rows[index], isSelected: false)
            }
            Spacer()
            pageIndicator
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .taskAfterNavigation {
            await libraryStore.loadSongsIfNeeded()
            await libraryStore.loadAlbumsIfNeeded()
            await libraryStore.loadArtistsIfNeeded()
            await libraryStore.loadPlaylistsIfNeeded()
            await libraryStore.loadGenresIfNeeded()
            await libraryStore.loadComposersIfNeeded()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { index in
                Circle()
                    .fill(index == page ? Color.black : Color.gray.opacity(0.35))
                    .frame(width: 5, height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }

    private func setup() {
        scope.configure(itemCount: 0)
        scope.onAction = { action in
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                page = (page + 1) % pages.count
            default:
                break
            }
        }
        iPlayrController.activate(scope)
    }
}
