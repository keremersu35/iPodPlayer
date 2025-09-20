import MusicKit

extension Playlist {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(
            artwork: artwork, id: id.rawValue, name: name, description: "")
    }
}

extension Album {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(artwork: artwork, id: id.rawValue, name: title, description: artistName)
    }
}

extension Track {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(artwork: artwork, id: id.rawValue, name: title, description: artistName)
    }
}
