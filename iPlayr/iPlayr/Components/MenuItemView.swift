import SwiftUI

struct Menu: Identifiable, Equatable {
    var id: Int = 0
    let name: String
    let next: Bool
    var value: String? = nil
}

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
            if let value = menu.value {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? .white : .blue)
            } else if menu.next && isSelected {
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
                    SelectedRowBackground()
                } else {
                    Rectangle()
                        .fill(.white)
                }
            }
        )
    }
}

struct SelectedRowBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.menuItemBackground1,
                     .menuItemBackground2,
                     .menuItemBackground3,
                     .menuItemBackground4,
                     .menuItemBackground5],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.menuItemHighlight)
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.menuItemRule)
                .frame(height: 1)
        }
    }
}
