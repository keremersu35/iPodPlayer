import SwiftUI

struct LibraryListView<Item, Row: View>: View {
    let title: String
    let emptyMessage: String
    let cached: () -> [Item]?
    let load: () async -> [Item]?
    let onSelect: (Item, Int) -> Void
    let row: (Item, Bool) -> Row

    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate
    @State private var scope: FocusScope
    @State private var viewState: ViewState = .loading
    @State private var items: [Item] = []

    init(
        title: String,
        scopeID: String,
        emptyMessage: String,
        cached: @escaping () -> [Item]? = { nil },
        load: @escaping () async -> [Item]?,
        onSelect: @escaping (Item, Int) -> Void,
        @ViewBuilder row: @escaping (Item, Bool) -> Row
    ) {
        self.title = title
        self.emptyMessage = emptyMessage
        self.cached = cached
        self.load = load
        self.onSelect = onSelect
        self.row = row
        _scope = State(initialValue: FocusScope(id: scopeID))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: title)
            ZStack {
                if viewState == .content {
                    itemList
                }
                StateView(state: viewState)
            }
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .taskAfterNavigation { await loadItems() }
    }

    private var itemList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { index in
                        row(items[index], index == scope.selection)
                            .id(index)
                    }
                }
            }
            .onChange(of: scope.selection) { _, newIndex in
                proxy.scrollTo(newIndex)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(scope.selection)
                }
            }
        }
    }

    private func setup() {
        scope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(scope)
        applyCachedItems()
    }

    private func applyCachedItems() {
        guard let cachedItems = cached(), !cachedItems.isEmpty else { return }
        items = cachedItems
        scope.configure(itemCount: cachedItems.count)
        viewState = .content
    }

    private func loadItems() async {
        guard viewState != .content else { return }
        viewState = .loading

        guard let loadedItems = await load() else {
            viewState = .error(message: libraryStore.errorMessage ?? String(localized: "An error occurred\nPlease try again later"))
            return
        }

        items = loadedItems
        guard !loadedItems.isEmpty else {
            viewState = .empty(message: emptyMessage)
            return
        }
        scope.configure(itemCount: loadedItems.count)
        viewState = .content
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            navigate(.pop)
        case .select:
            guard items.indices.contains(scope.selection) else { return }
            onSelect(items[scope.selection], scope.selection)
        default:
            break
        }
    }
}
