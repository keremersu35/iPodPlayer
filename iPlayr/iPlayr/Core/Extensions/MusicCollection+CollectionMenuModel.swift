import MusicKit

extension Playlist {
    func toCollectionMenuModel() -> CollectionMenuModel {
        return CollectionMenuModel(
            artwork: self.artwork,
            id: self.id.rawValue,
            name: self.name,
            description: ""
        )
    }
}

extension Album {
    func toCollectionMenuModel() -> CollectionMenuModel {
        return CollectionMenuModel(
            artwork: self.artwork,
            id: self.id.rawValue,
            name: self.title,
            description: self.artistName
        )
    }
}

extension Track {
    func toCollectionMenuModel() -> CollectionMenuModel {
        return CollectionMenuModel(
            artwork: self.artwork,
            id: self.id.rawValue,
            name: self.title,
            description: self.artistName
        )
    }
}
