import Foundation
import Observation

@MainActor
@Observable
final class FocusScope {
    let id: String
    private(set) var selection: Int = 0
    var itemCount: Int = 0 {
        didSet { clampSelection() }
    }
    @ObservationIgnored var onAction: ((ButtonAction) -> Void)?
    @ObservationIgnored var onScroll: ((Int) -> Bool)?
    @ObservationIgnored let handledTransportActions: Set<ButtonAction>

    init(id: String, handledTransportActions: Set<ButtonAction> = []) {
        self.id = id
        self.handledTransportActions = handledTransportActions
    }

    func configure(itemCount: Int, selection: Int = 0) {
        guard itemCount != self.itemCount else { return }
        self.itemCount = itemCount
        self.selection = itemCount > 0 ? max(0, min(selection, itemCount - 1)) : 0
    }

    func select(_ index: Int) {
        selection = itemCount > 0 ? max(0, min(index, itemCount - 1)) : 0
    }

    @discardableResult
    func moveUp() -> Bool {
        if let onScroll { return onScroll(-1) }
        guard selection > 0 else { return false }
        selection -= 1
        return true
    }

    @discardableResult
    func moveDown() -> Bool {
        if let onScroll { return onScroll(1) }
        guard itemCount > 0, selection < itemCount - 1 else { return false }
        selection += 1
        return true
    }

    private func clampSelection() {
        selection = itemCount > 0 ? min(selection, itemCount - 1) : 0
    }
}
