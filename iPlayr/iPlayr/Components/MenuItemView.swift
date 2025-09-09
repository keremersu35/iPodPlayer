import SwiftUI
import Equatable

struct Menu: Identifiable, Equatable {
    let id: Int
    let name: String
    let next: Bool
}

@Equatable
struct MenuItemView: View {
    var menu: Menu
    var isSelected: Bool

    var body: some View {
        HStack {
            Text(menu.name)
                .font(.system(size: 16))
                .fontWeight(.bold)
                .lineLimit(1)
            Spacer()
            if menu.next && isSelected {
                Image(systemName: ImageNames.System.chevronRight)
                    .font(.system(size: 14, weight: .heavy))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
}
