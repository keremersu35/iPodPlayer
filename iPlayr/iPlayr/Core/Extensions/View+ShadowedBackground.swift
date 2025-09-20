import SwiftUI

struct ShadowedBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Rectangle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.7), radius: 8, x: 4, y: 0)
            )
    }
}

extension View {
    func shadowedBackground() -> some View {
        modifier(ShadowedBackground())
    }
}
