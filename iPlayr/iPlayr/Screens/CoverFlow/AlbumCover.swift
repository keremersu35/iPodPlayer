import SwiftUI
import MusicKit

struct AlbumCover: View {
    let album: Album
    let isSelected: Bool
    @Binding var isSongList: Bool
    @State private var isFaceUp = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                albumArtwork
                songListOverlay
            }
            .frame(width: isFaceUp ? 300 : 160, height: isFaceUp ? 300 : 160)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onChange(of: isSongList) { _, newValue in
                if isSelected {
                    withAnimation(.linear(duration: 0.3)) {
                        isFaceUp = newValue
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private var albumArtwork: some View {
        Group {
            if let artwork = album.artwork {
                ArtworkImage(artwork, width: 160, height: 160)
            } else {
                Image(ImageNames.Custom.coverPlaceholder)
                    .resizable()
                    .frame(width: 160, height: 160)
            }
        }
        .modifier(FlipOpacity(pct: isFaceUp ? 0 : 1))
        .aspectRatio(contentMode: .fit)
        .rotation3DEffect(.degrees(isFaceUp ? 180 : 360), axis: (0, 1, 0))
        .reflection()
    }

    private var songListOverlay: some View {
        SongListView(album: album, isSelected: isSelected, isSongList: $isSongList)
            .frame(width: 300, height: 280)
            .background(Color.white)
            .border(.gray)
            .offset(y: 35)
            .modifier(FlipOpacity(pct: isFaceUp ? 1 : 0))
            .rotation3DEffect(.degrees(isFaceUp ? 0 : 180), axis: (0, 1, 0))
            .scaleEffect(isFaceUp ? 1 : 160 / 300)
            .zIndex(2)
    }
}
