import UIKit

extension iCarousel {
    var indexesForVisibleItems: [Int] {
        itemViews.keys.sorted()
    }

    var visibleItemViews: [UIView] {
        indexesForVisibleItems.compactMap { itemViews[$0] }
    }

    var currentItemView: UIView? {
        itemView(at: currentItemIndex)
    }

    func itemView(at index: Int) -> UIView? {
        itemViews[index]
    }

    func index(of itemView: UIView) -> Int? {
        itemViews.first { $0.value === itemView }?.key
    }

    func indexOfItemViewOrSubview(_ view: UIView) -> Int? {
        if let directIndex = index(of: view) {
            return directIndex
        }

        return findIndexInHierarchy(view)
    }

    private func findIndexInHierarchy(_ view: UIView) -> Int? {
        guard let superView = view.superview,
              view != contentView else {
            return nil
        }

        return indexOfItemViewOrSubview(superView)
    }

    func itemView(at point: CGPoint) -> UIView? {
        let sortedCells = getSortedCellsByDepth()
        let hitCell = findHitCell(in: sortedCells, at: point)
        return hitCell?.child
    }

    private func getSortedCellsByDepth() -> [ItemCell] {
        itemViews.values
            .compactMap { $0.itemCell }
            .sorted(by: compareViewDepth)
    }

    private func findHitCell(in cells: [ItemCell], at point: CGPoint) -> ItemCell? {
        cells.last { cell in
            cell.layer.hitTest(point) != nil
        }
    }
}

extension iCarousel {
    func setItemView(_ itemView: UIView, forIndex index: Int) {
        itemViews[index] = itemView
    }

    func removeView(at index: Int) {
        itemViews = rebuildItemViewsAfterRemoval(at: index)
    }

    private func rebuildItemViewsAfterRemoval(at targetIndex: Int) -> [Int: UIView] {
        indexesForVisibleItems.reduce(into: [:]) { result, currentIndex in
            if currentIndex < targetIndex {
                result[currentIndex] = itemViews[currentIndex]
            } else if currentIndex > targetIndex {
                result[currentIndex - 1] = itemViews[currentIndex]
            }
        }
    }

    func insert(_ itemView: UIView?, at index: Int) {
        itemViews = rebuildItemViewsAfterInsertion(at: index)

        if let itemView = itemView {
            setItemView(itemView, forIndex: index)
        }
    }

    private func rebuildItemViewsAfterInsertion(at targetIndex: Int) -> [Int: UIView] {
        indexesForVisibleItems.reduce(into: [:]) { result, currentIndex in
            if currentIndex < targetIndex {
                result[currentIndex] = itemViews[currentIndex]
            } else {
                result[currentIndex + 1] = itemViews[currentIndex]
            }
        }
    }
}

extension iCarousel {

    func queue(itemView: UIView, at index: Int) {
        guard let cell = itemView.itemCell else { return }

        if isPlaceholder(index: index) {
            queuePlaceholderView(itemView)
        } else {
            queueItemView(itemView)
        }

        prepareViewForReuse(cell)
    }

    func queue(_ itemView: UIView) {
        queue(itemView: itemView, at: 0)
    }

    private func isPlaceholder(index: Int) -> Bool {
        index < 0 || index >= numberOfItems
    }

    private func queueItemView(_ itemView: UIView) {
        itemViewPool.insert(itemView)
    }

    private func queuePlaceholderView(_ itemView: UIView) {
        placeholderViewPool.insert(itemView)
    }

    private func prepareViewForReuse(_ cell: ItemCell) {
        cell.layer.opacity = 0.0
    }
}

extension iCarousel {

    private func findNearestItemIndex() -> Int {
        let currentOffset = scrollOffset
        let roundedIndex = Int(round(currentOffset))
        return clamped(index: roundedIndex)
    }

    func centerCurrentItem() {
        scrollToItem(at: currentItemIndex, animated: true)
    }

    func isItemVisible(at index: Int) -> Bool {
        itemViews[index] != nil
    }

    func visibleRange() -> Range<Int>? {
        let visibleIndexes = indexesForVisibleItems
        guard let minIndex = visibleIndexes.min(),
              let maxIndex = visibleIndexes.max() else {
            return nil
        }

        return minIndex..<(maxIndex + 1)
    }
}

extension iCarousel {
    func performBatchUpdates(_ updates: () -> Void, completion: ((Bool) -> Void)? = nil) {
        let wasAnimating = isScrolling || isDecelerating

        stopAnimation()
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        updates()

        CATransaction.commit()

        if wasAnimating {
            startAnimation()
        }

        DispatchQueue.main.async {
            completion?(true)
        }
    }

    func invalidateLayout() {
        setNeedsLayout()
        layoutIfNeeded()
    }
}
