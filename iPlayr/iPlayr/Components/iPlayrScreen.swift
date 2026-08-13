import SwiftUI

struct iPlayrScreen: View {
    private static let screenHeight: CGFloat = 300
    private static let pushAnimation: Animation = .easeInOut(duration: NavigationTiming.pushDuration)

    @State private var menuStack: [Route] = [.home]
    @State private var fullScreenStack: [Route] = []
    @State private var menuDepth: Int = 1
    @State private var fullScreenDepth: Int = 0
    @State private var scopeStack: [FocusScope?] = []
    @Environment(iPlayrButtonController.self) var iPlayrController

    private var isFullScreen: Bool { fullScreenDepth > 0 }

    var body: some View {
        GeometryReader { geometry in
            contentView(geometry: geometry)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(height: Self.screenHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 6)
                        .foregroundColor(.screenFrame)
                )
        }
        .onNavigate(handleNavigation)
        .onAppear {
            iPlayrController.onMenuLongPress = { handleNavigation(.popToRoot) }
        }
    }

    private func contentView(geometry: GeometryProxy) -> some View {
        let fullWidth = geometry.size.width
        let halfWidth = fullWidth / 2

        return ZStack {
            stackLayer(fullScreenStack, depth: fullScreenDepth, width: fullWidth) {
                withAnimation(Self.pushAnimation) { fullScreenDepth = fullScreenStack.count }
            }
            .zIndex(1)

            splitScreenView(width: fullWidth, halfWidth: halfWidth)
                .zIndex(2)
        }
        .frame(width: fullWidth, height: Self.screenHeight)
        .clipped()
    }

    private func splitScreenView(width: CGFloat, halfWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            stackLayer(menuStack, depth: menuDepth, width: halfWidth) {
                withAnimation(Self.pushAnimation) { menuDepth = menuStack.count }
            }
            .offset(x: isFullScreen ? -halfWidth : 0)

            RightImageView(isActive: !isFullScreen)
                .frame(width: halfWidth, height: Self.screenHeight)
                .clipped()
                .offset(x: isFullScreen ? halfWidth : 0)
        }
        .frame(width: width, height: Self.screenHeight)
    }

    private func stackLayer(_ stack: [Route], depth: Int, width: CGFloat,
                            advance: @escaping () -> Void) -> some View {
        ZStack {
            ForEach(Array(stack.enumerated()), id: \.offset) { index, route in
                route.destination
                    .frame(width: width, height: Self.screenHeight)
                    .offset(x: CGFloat(index - depth + 1) * width)
                    .zIndex(Double(index))
                    .onAppear {
                        guard index == stack.count - 1, depth < stack.count else { return }
                        advance()
                    }
            }
        }
        .frame(width: width, height: Self.screenHeight)
        .clipped()
    }

    private func handleNavigation(_ navigationType: NavigationType) {
        switch navigationType {
        case .push(let route):
            scopeStack.append(iPlayrController.activeScope)
            if route.isFullScreen {
                fullScreenStack.append(route)
            } else {
                menuStack.append(route)
            }

        case .pop:
            guard isFullScreen || menuDepth > 1 else { return }
            withAnimation(Self.pushAnimation) {
                if isFullScreen {
                    fullScreenDepth -= 1
                } else {
                    menuDepth -= 1
                }
            } completion: {
                trimStacks()
            }
            if let saved = scopeStack.popLast(), let scope = saved {
                iPlayrController.activate(scope)
            }

        case .popToRoot:
            guard isFullScreen || menuDepth > 1 else { return }
            withAnimation(Self.pushAnimation) {
                fullScreenDepth = 0
                menuDepth = 1
            } completion: {
                trimStacks()
            }
            if let rootScope = scopeStack.first ?? nil {
                iPlayrController.activate(rootScope)
            }
            scopeStack.removeAll()
        }
    }

    private func trimStacks() {
        if fullScreenStack.count > fullScreenDepth {
            fullScreenStack = Array(fullScreenStack.prefix(fullScreenDepth))
        }
        if menuStack.count > menuDepth {
            menuStack = Array(menuStack.prefix(menuDepth))
        }
    }
}

extension View {
    func onNavigate(_ action: @escaping NavigateAction.Action) -> some View {
        environment(\.navigate, NavigateAction(action: action))
    }
}
