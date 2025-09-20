import UIKit

extension iCarousel {
    func queue(itemView view: UIView) {
        prepareViewForReuse(view)
        itemViewPool.insert(view)
    }

    func queue(placeholderView view: UIView) {
        prepareViewForReuse(view)
        placeholderViewPool.insert(view)
    }

    func queue(_ view: UIView, at index: Int) {
        if isPlaceholderIndex(index) {
            queue(placeholderView: view)
        } else {
            queue(itemView: view)
        }
    }

    private func isPlaceholderIndex(_ index: Int) -> Bool {
        index < 0 || index >= numberOfItems
    }

    private func prepareViewForReuse(_ view: UIView) {
        view.itemCell?.layer.opacity = 0.0
        view.itemCell?.layer.transform = CATransform3DIdentity
    }

    func dequeuePlaceholderView() -> UIView? {
        placeholderViewPool.popFirst()
    }
}
