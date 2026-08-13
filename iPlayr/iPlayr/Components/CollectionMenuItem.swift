import SwiftUI
import MusicKit

struct CollectionMenuModel: Equatable {
    let artwork: Artwork?
    let name: String
    let description: String
}

struct CollectionMenuItem: View {
    var model: CollectionMenuModel
    var isSelected: Bool

    var body: some View {
        HStack {
            artworkView
            VStack(alignment: .leading) {
                Text(model.name)
                    .font(.system(size: 16))
                    .fontWeight(.bold)
                Text(model.description)
                    .font(.system(size: 14))
                    .fontWeight(.regular)
            }
            Spacer()
            if isSelected {
                Image(systemName: ImageNames.System.chevronRight)
                    .font(.system(size: 14))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
        .padding(.trailing, 8)
        .foregroundColor(isSelected ? .white : .black)
        .background(
            Group {
                if isSelected {
                    SelectedRowBackground()
                } else {
                    Rectangle()
                        .fill(.white)
                }
            }
        )
    }

    @ViewBuilder
    private var artworkView: some View {
        if let artwork = model.artwork {
            ArtworkImage(artwork, width: 50, height: 50)
        } else {
            Image(ImageNames.Custom.coverPlaceholder)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
        }
    }
}
