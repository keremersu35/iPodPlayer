import UIKit

extension iCarousel {
    func compareViewDepth(view1: ItemCell, view2: ItemCell) -> Bool {
        let depth1 = calculateZDepth(from: view1.layer.transform)
        let depth2 = calculateZDepth(from: view2.layer.transform)

        var difference = depth1 - depth2

        if abs(difference) < Constants.floatErrorMargin {
            difference = calculatePositionalDifference(view1: view1, view2: view2)
        }

        return difference < 0
    }

    private func calculateZDepth(from transform: CATransform3D) -> CGFloat {
        transform.m13 + transform.m23 + transform.m33 + transform.m43
    }

    private func calculatePositionalDifference(view1: ItemCell, view2: ItemCell) -> CGFloat {
        guard let currentItemCell = currentItemView?.itemCell else { return 0 }

        let currentTransform = currentItemCell.layer.transform

        if isVertical {
            return calculateVerticalDifference(
                view1: view1,
                view2: view2,
                reference: currentTransform
            )
        } else {
            return calculateHorizontalDifference(
                view1: view1,
                view2: view2,
                reference: currentTransform
            )
        }
    }

    private func calculateVerticalDifference(view1: ItemCell, view2: ItemCell, reference: CATransform3D) -> CGFloat {
        let y1 = extractYPosition(from: view1.layer.transform)
        let y2 = extractYPosition(from: view2.layer.transform)
        let y3 = extractYPosition(from: reference)

        return abs(y2 - y3) - abs(y1 - y3)
    }

    private func calculateHorizontalDifference(view1: ItemCell, view2: ItemCell, reference: CATransform3D) -> CGFloat {
        let x1 = extractXPosition(from: view1.layer.transform)
        let x2 = extractXPosition(from: view2.layer.transform)
        let x3 = extractXPosition(from: reference)

        return abs(x2 - x3) - abs(x1 - x3)
    }

    private func extractYPosition(from transform: CATransform3D) -> CGFloat {
        transform.m12 + transform.m22 + transform.m32 + transform.m42
    }

    private func extractXPosition(from transform: CATransform3D) -> CGFloat {
        transform.m11 + transform.m21 + transform.m31 + transform.m41
    }

    func depthSortViews() {
        let sortedCells = itemViews.values
            .compactMap { $0.itemCell }
            .sorted(by: compareViewDepth)

        sortedCells.forEach { cell in
            contentView.bringSubviewToFront(cell)
        }
    }
}

extension iCarousel {
    func offsetForItem(at index: Int) -> CGFloat {
        var offset = CGFloat(index) - scrollOffset

        if isWrapEnabled {
            offset = normalizeWrappedOffset(offset)
        }

        return offset
    }

    private func normalizeWrappedOffset(_ offset: CGFloat) -> CGFloat {
        let itemCount = CGFloat(numberOfItems)
        let halfCount = itemCount / 2.0

        var normalizedOffset = offset

        if offset > halfCount {
            normalizedOffset -= itemCount
        } else if offset < -halfCount {
            normalizedOffset += itemCount
        }

        return normalizedOffset
    }
}

extension iCarousel {
    func transformItemView(_ itemView: UIView, at index: Int) {
        let offset = offsetForItem(at: index)

        guard let cell = itemView.itemCell else {
            itemView.layoutIfNeeded()
            return
        }

        configureBasicCellProperties(cell, at: index, offset: offset)
        calculateToggleIfNeeded(offset: offset)
        applyTransformation(to: cell, itemView: itemView, offset: offset)
    }

    private func configureBasicCellProperties(_ cell: ItemCell, at index: Int, offset: CGFloat) {
        cell.layer.opacity = Float(animator.alphaForItem(with: offset))
        cell.center = calculateCellCenter()
        cell.isUserInteractionEnabled = shouldEnableUserInteraction(at: index)
        cell.layer.rasterizationScale = UIScreen.main.scale
    }

    private func calculateCellCenter() -> CGPoint {
        CGPoint(
            x: bounds.size.width / 2.0 + contentOffset.width,
            y: bounds.size.height / 2.0 + contentOffset.height
        )
    }

    private func shouldEnableUserInteraction(at index: Int) -> Bool {
        !centerItemWhenSelected || index == currentItemIndex
    }

    private func calculateToggleIfNeeded(offset: CGFloat) {
        guard shouldCalculateToggle else { return }

        let clampedOffset = clampOffset(offset)
        toggle = calculateToggleValue(offset: offset, clampedOffset: clampedOffset)
    }

    private var shouldCalculateToggle: Bool {
        isDecelerating ||
        (isScrolling && !isDragging && !state.didDrag) ||
        (canAutoscroll && !isDragging) ||
        isAtScrollBoundary
    }

    private var isAtScrollBoundary: Bool {
        !isWrapEnabled && (scrollOffset < 0 || scrollOffset >= CGFloat(numberOfItems - 1))
    }

    private func clampOffset(_ offset: CGFloat) -> CGFloat {
        max(-1.0, min(1.0, offset))
    }

    private func calculateToggleValue(offset: CGFloat, clampedOffset: CGFloat) -> CGFloat {
        if offset > 0 {
            return offset <= 0.5 ? -clampedOffset : (1.0 - clampedOffset)
        } else {
            return offset > -0.5 ? -clampedOffset : (-1.0 - clampedOffset)
        }
    }

    private func applyTransformation(to cell: ItemCell, itemView: UIView, offset: CGFloat) {
        let transform = animator.transformForItemView(with: offset, in: self)
        cell.layer.transform = transform

        let shouldShowBackfaces = calculateBackfaceVisibility(itemView: itemView, transform: transform)
        cell.isHidden = !shouldShowBackfaces
    }

    private func calculateBackfaceVisibility(itemView: UIView, transform: CATransform3D) -> Bool {
        var showBackfaces = itemView.layer.isDoubleSided

        if showBackfaces {
            showBackfaces = animator.showBackfaces(view: itemView, in: self)
        }

        return showBackfaces || (transform.m33 > 0.0)
    }

    func transformItemViews() {
        itemViews.forEach { index, itemView in
            transformItemView(itemView, at: index)
        }
    }
}

extension iCarousel {
    func updateItemWidth() {
        requestItemWidthFromDelegate()
        loadInitialViewIfNeeded()
    }

    private func requestItemWidthFromDelegate() {
        if let delegateWidth = delegate?.carouselItemWidth(self), delegateWidth > 0 {
            itemWidth = delegateWidth
        }
    }

    private func loadInitialViewIfNeeded() {
        if numberOfItems > 0 && itemViews.isEmpty {
            loadView(at: 0)
        } else if numberOfPlaceholders > 0 && itemViews.isEmpty {
            loadView(at: -1)
        }
    }

    func updateNumberOfVisibleItems() {
        numberOfVisibleItems = animator._numberOfVisibleItems(in: self)
    }

    func layOutItemViews() {
        guard dataSource != nil else { return }

        configureLayoutProperties()
        updateLayoutDimensions()
        handleScrollAdjustment()
        didScroll()
    }

    private func configureLayoutProperties() {
        isWrapEnabled = animator.isWrapEnabled
        state.numberOfPlaceholdersToShow = isWrapEnabled ? 0 : numberOfPlaceholders
        state.previousScrollOffset = scrollOffset
        offsetMultiplier = animator.offsetMultiplier
    }

    private func updateLayoutDimensions() {
        updateItemWidth()
        updateNumberOfVisibleItems()
    }

    private func handleScrollAdjustment() {
        guard !isScrolling && !isDecelerating && !canAutoscroll else { return }

        if scrollToItemBoundary && currentItemIndex != -1 {
            scrollToItem(at: currentItemIndex, animated: true)
        } else {
            _scrollOffset = clamped(offset: scrollOffset)
        }
    }
}

extension iCarousel {
    var relativeWidth: CGFloat {
        bounds.relativeWidth(isVertical: isVertical)
    }
}

extension CGRect {
    func relativeWidth(isVertical: Bool) -> CGFloat {
        isVertical ? size.height : size.width
    }
}

extension UIView {
    func _relativeWidth(_ isVertical: Bool) -> CGFloat {
        bounds.relativeWidth(isVertical: isVertical)
    }
}
