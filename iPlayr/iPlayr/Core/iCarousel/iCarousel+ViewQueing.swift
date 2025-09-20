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

    func dequeueItemView() -> UIView? {
        itemViewPool.popFirst()
    }

    func dequeuePlaceholderView() -> UIView? {
        placeholderViewPool.popFirst()
    }

    func clearViewPools() {
        itemViewPool.removeAll()
        placeholderViewPool.removeAll()
    }

    var pooledItemCount: Int {
        itemViewPool.count
    }

    var pooledPlaceholderCount: Int {
        placeholderViewPool.count
    }
}

extension iCarousel {
    func preloadViews(count: Int = 5) {
        guard count > 0 else { return }

        for _ in 0..<count {
            if let view = dataSource?.carousel(self, viewForItemAt: 0, reusingView: nil) {
                queue(itemView: view)
            }
        }
    }

    func optimizeMemoryUsage() {
        let maxPoolSize = max(numberOfVisibleItems * 2, 10)

        while itemViewPool.count > maxPoolSize {
            _ = itemViewPool.popFirst()
        }

        while placeholderViewPool.count > maxPoolSize {
            _ = placeholderViewPool.popFirst()
        }
    }
}
