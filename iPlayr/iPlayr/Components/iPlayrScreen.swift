import SwiftUI

struct iPlayrScreen: View {
    @State private var menuStack: [Route] = [.home]
    @State private var fullScreenStack: [Route] = []
    @State private var isForwardTransition: Bool = true
    @State private var scopeBeforeFullScreen: FocusScope?
    @EnvironmentObject var iPlayrController: iPlayrButtonController

    private var currentMenuRoute: Route {
        menuStack.last ?? .home
    }

    private var currentFullScreenRoute: Route? {
        fullScreenStack.last
    }

    private var isFullScreen: Bool {
        !fullScreenStack.isEmpty
    }

    var body: some View {
        GeometryReader { geometry in
            contentView(geometry: geometry)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(height: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 6)
                        .foregroundColor(.screenFrame)
                )
        }
        .onNavigate(handleNavigation)
        .onChange(of: fullScreenStack.isEmpty) { _, isEmpty in
            guard isEmpty, let scope = scopeBeforeFullScreen else { return }
            iPlayrController.activate(scope)
            scopeBeforeFullScreen = nil
        }
    }

    private func contentView(geometry: GeometryProxy) -> some View {
        let halfWidth = geometry.size.width / 2

        return ZStack {
            if let fullScreenRoute = currentFullScreenRoute {
                fullScreenRoute.destination
                    .id(fullScreenRoute)
                    .environmentObject(iPlayrController)
                    .frame(width: geometry.size.width, height: 300)
                    .transition(
                        isForwardTransition
                            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
                            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
                    )
                    .zIndex(1)
            }

            splitScreenView(geometry: geometry, halfWidth: halfWidth)
                .zIndex(2)
        }
        .frame(width: geometry.size.width, height: 300)
        .clipped()
    }

    private func splitScreenView(geometry: GeometryProxy, halfWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ZStack {
                currentMenuRoute.destination
                    .id(currentMenuRoute)
                    .environmentObject(iPlayrController)
                    .frame(width: halfWidth, height: 300)
                    .transition(
                        isForwardTransition
                            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
                            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
                    )
            }
            .frame(width: halfWidth, height: 300)
            .clipped()
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.black.opacity(0.25), .clear],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .frame(width: 3)
            }
            .offset(x: isFullScreen ? -halfWidth : 0)

            RightImageView()
                .frame(width: halfWidth, height: 300)
                .clipped()
                .offset(x: isFullScreen ? halfWidth : 0)
        }
        .frame(width: geometry.size.width, height: 300)
        .clipped()
    }

    private func handleNavigation(_ navigationType: NavigationType) {
        switch navigationType {
        case .push(let route):
            isForwardTransition = true
            withAnimation(.easeInOut(duration: 0.28)) {
                if route.isFullScreen {
                    if fullScreenStack.isEmpty {
                        scopeBeforeFullScreen = iPlayrController.activeScope
                    }
                    fullScreenStack.append(route)
                } else {
                    menuStack.append(route)
                }
            }
        case .pop:
            isForwardTransition = false
            withAnimation(.easeInOut(duration: 0.28)) {
                if !fullScreenStack.isEmpty {
                    fullScreenStack.removeLast()
                } else if menuStack.count > 1 {
                    menuStack.removeLast()
                }
            }
        }
    }
}

extension View {
    func onNavigate(_ action: @escaping NavigateAction.Action) -> some View {
        environment(\.navigate, NavigateAction(action: action))
    }
}
