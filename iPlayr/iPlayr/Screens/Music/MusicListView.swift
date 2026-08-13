import SwiftUI

struct MusicListView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(AppleMusicManager.self) private var playerManager
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "music")

    private var entries: [(menu: Menu, route: Route)] {
        var entries: [(menu: Menu, route: Route)] = [
            (.init(id: 0, name: String(localized: "Cover Flow"), next: true), .coverFlow),
            (.init(id: 1, name: String(localized: "Playlists"), next: true), .playlists),
            (.init(id: 2, name: String(localized: "Albums"), next: true), .albums),
        ]
        if playerManager.currentTrack != nil {
            entries.append((.init(id: 3, name: String(localized: "Now Playing"), next: true), .nowPlaying))
        }
        return entries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Music"))
            ForEach(entries.indices, id: \.self) { index in
                MenuItemView(menu: entries[index].menu, isSelected: scope.selection == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .onChange(of: entries.count) { _, count in
            scope.itemCount = count
        }
    }

    private func setup() {
        scope.configure(itemCount: entries.count)
        scope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            navigate(.pop)
        case .select:
            guard entries.indices.contains(scope.selection) else { return }
            navigate(.push(entries[scope.selection].route))
        default: break
        }
    }
}
