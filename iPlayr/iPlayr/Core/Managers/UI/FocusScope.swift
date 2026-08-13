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

    init(id: String) {
        self.id = id
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
        guard selection > 0 else { return false }
        selection -= 1
        return true
    }

    @discardableResult
    func moveDown() -> Bool {
        guard itemCount > 0, selection < itemCount - 1 else { return false }
        selection += 1
        return true
    }

    private func clampSelection() {
        selection = itemCount > 0 ? min(selection, itemCount - 1) : 0
    }
}
