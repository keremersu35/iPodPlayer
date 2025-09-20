import MusicKit

extension Playlist {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(
            artwork: artwork, name: name, description: "")
    }
}

extension Album {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(artwork: artwork, name: title, description: artistName)
    }
}

extension Track {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(artwork: artwork, name: title, description: artistName)
    }
}
