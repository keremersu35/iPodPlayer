import SwiftUICore

private struct ReflectionModifier: ViewModifier {
    let offsetY: CGFloat
    func body(content: Content) -> some View {
        content
            .background(
                content
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [.init(color: .white, location: 0.0), .init(color: .clear, location: 0.1)]),
                            startPoint: .bottom,
                            endPoint: .top)
                    )
                    .scaleEffect(x: 1.0, y: -2.0, anchor: .bottom)
                    .opacity(0.3)
                    .offset(y: offsetY)
            )
    }
}

extension View {
    func reflection(offsetY: CGFloat = 1) -> some View {
        modifier(ReflectionModifier(offsetY: offsetY))
    }
}
