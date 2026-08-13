import Foundation

struct NavigationEntry: Identifiable {
    let id = UUID()
    let route: Route
    let restoreScope: FocusScope?
}

struct NavigationLayer {
    private let minimumDepth: Int
    private(set) var entries: [NavigationEntry]
    private(set) var visibleDepth: Int
    private(set) var isSettlePending: Bool = false

    init(root: Route? = nil) {
        if let root {
            entries = [NavigationEntry(route: root, restoreScope: nil)]
            minimumDepth = 1
        } else {
            entries = []
            minimumDepth = 0
        }
        visibleDepth = minimumDepth
    }

    var isEmpty: Bool { visibleDepth == 0 }
    var canPop: Bool { visibleDepth > minimumDepth }

    var topRestoreScope: FocusScope? {
        guard canPop, entries.indices.contains(visibleDepth - 1) else { return nil }
        return entries[visibleDepth - 1].restoreScope
    }

    var rootRestoreScope: FocusScope? {
        guard canPop, entries.indices.contains(minimumDepth) else { return nil }
        return entries[minimumDepth].restoreScope
    }

    func offset(forEntryAt index: Int, width: CGFloat) -> CGFloat {
        CGFloat(index - visibleDepth + 1) * width
    }

    func isTopEntry(at index: Int) -> Bool {
        index == entries.count - 1
    }

    mutating func push(_ route: Route, restoreScope: FocusScope?) {
        trim()
        entries.append(NavigationEntry(route: route, restoreScope: restoreScope))
        isSettlePending = true
    }

    mutating func settle() {
        guard isSettlePending else { return }
        visibleDepth = entries.count
        isSettlePending = false
    }

    mutating func pop() {
        guard canPop else { return }
        isSettlePending = false
        visibleDepth -= 1
    }

    mutating func popToRoot() {
        isSettlePending = false
        visibleDepth = minimumDepth
    }

    mutating func trim() {
        guard !isSettlePending, entries.count > visibleDepth else { return }
        entries.removeLast(entries.count - visibleDepth)
    }
}
