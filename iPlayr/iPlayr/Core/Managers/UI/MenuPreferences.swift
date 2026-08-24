import Foundation
import Observation

enum MusicMenuItem: String, CaseIterable, Sendable {
    case coverFlow
    case playlists
    case artists
    case albums
    case songs
    case genres
    case composers

    var title: String {
        switch self {
        case .coverFlow: return String(localized: "Cover Flow")
        case .playlists: return String(localized: "Playlists")
        case .artists: return String(localized: "Artists")
        case .albums: return String(localized: "Albums")
        case .songs: return String(localized: "Songs")
        case .genres: return String(localized: "Genres")
        case .composers: return String(localized: "Composers")
        }
    }

    var route: Route {
        switch self {
        case .coverFlow: return .coverFlow
        case .playlists: return .playlists
        case .artists: return .artists(genre: nil)
        case .albums: return .albums
        case .songs: return .songs
        case .genres: return .genres
        case .composers: return .composers
        }
    }
}

@MainActor
@Observable
final class MenuPreferences {
    private(set) var musicMenu: [MusicMenuItem]
    private(set) var mainMenuShortcuts: [MusicMenuItem]

    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        musicMenu = Self.read(UserDefaultsKeys.musicMenuItems.rawValue, default: MusicMenuItem.allCases)
        mainMenuShortcuts = Self.read(UserDefaultsKeys.mainMenuShortcuts.rawValue, default: [])
    }

    func isInMusicMenu(_ item: MusicMenuItem) -> Bool { musicMenu.contains(item) }
    func isInMainMenu(_ item: MusicMenuItem) -> Bool { mainMenuShortcuts.contains(item) }

    func toggleMusicMenu(_ item: MusicMenuItem) {
        musicMenu = Self.toggling(item, in: musicMenu)
        write(musicMenu, forKey: UserDefaultsKeys.musicMenuItems.rawValue)
    }

    func toggleMainMenu(_ item: MusicMenuItem) {
        mainMenuShortcuts = Self.toggling(item, in: mainMenuShortcuts)
        write(mainMenuShortcuts, forKey: UserDefaultsKeys.mainMenuShortcuts.rawValue)
    }

    func resetMusicMenu() {
        musicMenu = MusicMenuItem.allCases
        write(musicMenu, forKey: UserDefaultsKeys.musicMenuItems.rawValue)
    }

    func resetMainMenu() {
        mainMenuShortcuts = []
        write(mainMenuShortcuts, forKey: UserDefaultsKeys.mainMenuShortcuts.rawValue)
    }

    private static func toggling(_ item: MusicMenuItem, in items: [MusicMenuItem]) -> [MusicMenuItem] {
        var updated = items
        if let index = updated.firstIndex(of: item) {
            updated.remove(at: index)
        } else {
            updated.append(item)
        }
        return MusicMenuItem.allCases.filter { updated.contains($0) }
    }

    private static func read(_ key: String, default fallback: [MusicMenuItem]) -> [MusicMenuItem] {
        guard let raw = UserDefaults.standard.array(forKey: key) as? [String] else { return fallback }
        return raw.compactMap(MusicMenuItem.init(rawValue:))
    }

    private func write(_ items: [MusicMenuItem], forKey key: String) {
        defaults.set(items.map(\.rawValue), forKey: key)
    }
}
