import SwiftUI

struct iPlayrScreen: View {
    @State private var routes: [Route] = []
    @State private var hasRightView: Bool = true
    @State private var isNavigating: Bool = false
    @State private var isShowingSnackbar: Bool = false
    @State private var snackbarMessage: String = ""
    @EnvironmentObject var iPlayrController: iPlayrButtonController
    
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
                .onChange(of: iPlayrController.hasRightView) { _, newValue in
                    hasRightView = newValue
                }
        }
    }

    @ViewBuilder
    private func contentView(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            createNavigationStack(geometry: geometry)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 10, y: 5)
                .zIndex(1)

            if hasRightView {
                RightImageView()
                    .frame(width: geometry.size.width / 2, alignment: .bottomLeading)
                    .transition(.move(edge: .trailing))
                    .zIndex(0)
            }
        }
    }

    private func createNavigationStack(geometry: GeometryProxy) -> some View {
        NavigationStack(path: $routes) {
            HomeListView()
                .environmentObject(iPlayrController)
                .frame(width: hasRightView ? geometry.size.width / 2 : geometry.size.width)
                .animation(.easeInOut, value: hasRightView)
                .navigationDestination(for: Route.self) { route in
                    route.destination.environmentObject(iPlayrController)
                }
        }
        .onNavigate { navType in
            handleNavigation(navType)
        }
    }

    private func handleNavigation(_ navType: NavigationType) {
        guard !isNavigating else { return }
        isNavigating = true
        
        switch navType {
        case .push(let route):
            routes.append(route)
            
        case .unwind(let route):
            unwindNavigation(to: route)

        case .resetTo(let route):
            routes = [route]
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isNavigating = false
        }
    }

    private func unwindNavigation(to route: Route) {
        switch route {
        case .home:
            routes.removeAll()
            
        case .coverFlow:
            if let index = routes.firstIndex(of: .coverFlow) {
                routes = Array(routes.prefix(through: index))
            }

        default:
            if let index = routes.firstIndex(of: route) {
                routes = Array(routes.prefix(upTo: index + 1))
            }
        }
    }
}

extension View {
    func onNavigate(_ action: @escaping NavigateAction.Action) -> some View {
        environment(\.navigate, NavigateAction(action: action))
    }
}
