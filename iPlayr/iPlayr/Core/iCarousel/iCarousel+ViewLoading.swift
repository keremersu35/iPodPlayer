import UIKit

extension iCarousel {
    final class ItemCell: UIView {
        let index: Int
        var child: UIView {
            didSet {
                replaceChild(oldValue: oldValue)
            }
        }

        init(child: UIView, index: Int, frame: CGRect = .zero) {
            self.child = child
            self.index = index
            super.init(frame: frame)
            setupInitialChild()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupInitialChild() {
            addSubview(child)
            layer.opacity = 0
        }

        private func replaceChild(oldValue: UIView) {
            oldValue.removeFromSuperview()
            addSubview(child)
            setNeedsLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            centerChildView()
        }

        private func centerChildView() {
            child.frame.origin = CGPoint(
                x: (bounds.size.width - child.frame.size.width) / 2.0,
                y: (bounds.size.height - child.frame.size.height) / 2.0
            )
        }
    }
}

extension UIView {
    var itemCell: iCarousel.ItemCell? {
        superview as? iCarousel.ItemCell
    }
}

extension iCarousel {
    @discardableResult
    func loadView(at index: Int, withContainerView containerView: ItemCell? = nil) -> UIView {
        transactionAnimated(false) {
            let view = createView(at: index)
            setItemView(view, forIndex: index)

            if let containerView = containerView {
                updateExistingContainer(containerView, with: view, at: index)
            } else {
                addNewContainer(with: view, at: index)
            }

            finalizeViewLoading(view, at: index)
            return view
        }
    }

    private func updateExistingContainer(_ containerView: ItemCell, with view: UIView, at index: Int) {
        configureContainerBounds(containerView, for: view)
        queue(containerView.child, at: index)
        containerView.child = view
    }

    private func configureContainerBounds(_ containerView: ItemCell, for view: UIView) {
        let viewSize = view.frame.size

        if isVertical {
            containerView.bounds.size = CGSize(
                width: viewSize.width,
                height: min(itemWidth, viewSize.height)
            )
        } else {
            containerView.bounds.size = CGSize(
                width: min(itemWidth, viewSize.width),
                height: viewSize.height
            )
        }
    }

    private func addNewContainer(with view: UIView, at index: Int) {
        let itemCell = createItemCell(view, index: index)
        contentView.addSubview(itemCell)
    }

    private func finalizeViewLoading(_ view: UIView, at index: Int) {
        view.itemCell?.layer.opacity = 0.0
        transformItemView(view, at: index)
    }

    func loadUnloadViews() {
        updateViewConfiguration()
        var visibleIndices = calculateVisibleIndices()
        unloadInvisibleViews(visibleIndices: &visibleIndices)
        loadMissingViews(visibleIndices: visibleIndices)
    }

    private func updateViewConfiguration() {
        updateItemWidth()
        updateNumberOfVisibleItems()
    }

    private func calculateVisibleIndices() -> Set<Int> {
        var visibleIndices = Set<Int>()
        let offset = calculateStartOffset()

        for i in 0..<numberOfVisibleItems {
            let index = normalizeIndex(i + offset)
            let alpha = animator.alphaForItem(with: offsetForItem(at: index))

            if alpha > 0 {
                visibleIndices.insert(index)
            }
        }

        return visibleIndices
    }

    private func calculateStartOffset() -> Int {
        var offset = currentItemIndex - numberOfVisibleItems / 2

        if !isWrapEnabled {
            let bounds = calculateOffsetBounds()
            offset = max(bounds.min, min(bounds.max, offset))
        }

        return offset
    }

    private func calculateOffsetBounds() -> (min: Int, max: Int) {
        let minOffset = -Int(ceil(CGFloat(state.numberOfPlaceholdersToShow) / 2.0))
        let maxOffset = numberOfItems - 1 + state.numberOfPlaceholdersToShow / 2
        let adjustedMax = maxOffset - numberOfVisibleItems + 1

        return (min: minOffset, max: adjustedMax)
    }

    private func normalizeIndex(_ index: Int) -> Int {
        isWrapEnabled ? clamped(index: index) : index
    }

    private func unloadInvisibleViews(visibleIndices: inout Set<Int>) {
        itemViews.forEach { index, view in
            if visibleIndices.contains(index) {
                visibleIndices.remove(index)
            } else {
                unloadView(view, at: index)
            }
        }
    }

    private func unloadView(_ view: UIView, at index: Int) {
        queue(view, at: index)
        view.itemCell?.removeFromSuperview()
        itemViews[index] = nil
    }

    private func loadMissingViews(visibleIndices: Set<Int>) {
        visibleIndices.forEach { index in
            if itemViews[index] == nil {
                loadView(at: index)
            }
        }
    }

    func reloadData() {
        clearExistingViews()
        initializeDataConfiguration()
        resetViewState()
        handleInitialScroll()
    }

    private func clearExistingViews() {
        itemViews.values.forEach { view in
            view.itemCell?.removeFromSuperview()
        }
    }

    private func initializeDataConfiguration() {
        guard let dataSource = dataSource else { return }

        numberOfVisibleItems = 0
        numberOfItems = dataSource.numberOfItems(in: self)
        numberOfPlaceholders = dataSource.numberOfPlaceholders(in: self)
    }

    private func resetViewState() {
        itemViews = [:]
        itemViewPool = []
        placeholderViewPool = []
        setNeedsLayout()
    }

    private func handleInitialScroll() {
        if numberOfItems > 0 && scrollOffset < 0.0 {
            let shouldAnimate = numberOfPlaceholders > 0
            scrollToItem(at: 0, animated: shouldAnimate)
        }
    }
}

extension iCarousel {
    func createItemCell(_ view: UIView, index: Int) -> ItemCell {
        ensureItemWidthIsSet(for: view)
        let frame = calculateCellFrame(for: view)
        return ItemCell(child: view, index: index, frame: frame)
    }

    private func ensureItemWidthIsSet(for view: UIView) {
        if itemWidth <= 0 {
            itemWidth = view._relativeWidth(isVertical)
        }
    }

    private func calculateCellFrame(for view: UIView) -> CGRect {
        var frame = view.bounds

        if isVertical {
            frame.size.height = itemWidth
        } else {
            frame.size.width = itemWidth
        }

        return frame
    }

    private func createView(at index: Int) -> UIView {
        let viewType = determineViewType(for: index)
        return requestViewFromDataSource(type: viewType, index: index) ?? createDefaultView()
    }

    private func determineViewType(for index: Int) -> ViewType {
        if index < 0 {
            return .placeholderBefore(adjustedIndex: calculatePlaceholderBeforeIndex(index))
        } else if index >= numberOfItems {
            return .placeholderAfter(adjustedIndex: calculatePlaceholderAfterIndex(index))
        } else {
            return .item(index: index)
        }
    }

    private enum ViewType {
        case item(index: Int)
        case placeholderBefore(adjustedIndex: Int)
        case placeholderAfter(adjustedIndex: Int)
    }

    private func calculatePlaceholderBeforeIndex(_ index: Int) -> Int {
        Int(ceil(CGFloat(state.numberOfPlaceholdersToShow) / 2.0)) + index
    }

    private func calculatePlaceholderAfterIndex(_ index: Int) -> Int {
        Int(CGFloat(state.numberOfPlaceholdersToShow) / 2.0) + index - numberOfItems
    }

    private func requestViewFromDataSource(type: ViewType, index: Int) -> UIView? {
        switch type {
        case .item(let itemIndex):
            return dataSource?.carousel(self, viewForItemAt: itemIndex, reusingView: dequeueItemView())
        case .placeholderBefore(let adjustedIndex), .placeholderAfter(let adjustedIndex):
            return dataSource?.carousel(self, placeholderViewAt: adjustedIndex, reusingView: dequeuePlaceholderView())
        }
    }

    private func createDefaultView() -> UIView {
        UIView()
    }
}
