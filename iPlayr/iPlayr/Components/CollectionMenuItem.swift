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
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.menuItemBackground1,
                                         .menuItemBackground2,
                                         .menuItemBackground3,
                                         .menuItemBackground4,
                                         .menuItemBackground5],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .shadow(.inner(color: .black.opacity(0.25), radius: 8, x: 0, y: -4))
                        )
                } else {
                    Rectangle()
                        .fill(.white)
                }
            }
        )
    }

    @ViewBuilder
    private var artworkView: some View {
        if let artwork = model.artwork, model.artwork?.backgroundColor != nil {
            ArtworkImage(artwork, width: 50, height: 50)
        } else {
            Image(ImageNames.Custom.coverPlaceholder)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
        }
    }
}
