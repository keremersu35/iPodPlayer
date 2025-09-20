import UIKit

extension iCarousel {
    var currentItemIndex: Int {
        get { clamped(index: Int(round(scrollOffset))) }
        set { scrollOffset = CGFloat(newValue) }
    }

    func scrollBy(offset: CGFloat, duration: TimeInterval) {
        if duration > 0 {
            startScrollAnimation(to: calculateScrollTarget(offset), duration: duration)
        } else {
            scrollOffset += offset
        }
    }

    private func startScrollAnimation(to endOffset: CGFloat, duration: TimeInterval) {
        resetScrollState()
        setupScrollAnimation(endOffset: endOffset, duration: duration)
        notifyScrollAnimationStart()
        startAnimation()
    }

    private func resetScrollState() {
        isDecelerating = false
        isScrolling = true
    }

    private func setupScrollAnimation(endOffset: CGFloat, duration: TimeInterval) {
        state.startTime = CACurrentMediaTime()
        state.startOffset = scrollOffset
        state.endOffset = isWrapEnabled ? endOffset : clamped(offset: endOffset)
        state.scrollDuration = duration
    }

    private func calculateScrollTarget(_ offset: CGFloat) -> CGFloat {
        scrollOffset + offset
    }

    private func notifyScrollAnimationStart() {
        delegate?.carouselWillBeginScrollingAnimation(self)
    }

    func scrollTo(offset: CGFloat, duration: TimeInterval) {
        let minDistance = minScrollDistance(fromOffset: scrollOffset, toOffset: offset)
        scrollBy(offset: minDistance, duration: duration)
    }

    func scrollByNumberOfItems(_ itemCount: Int, duration: TimeInterval) {
        if duration > 0 {
            let offset = calculateItemScrollOffset(itemCount)
            scrollBy(offset: offset, duration: duration)
        } else {
            scrollOffset = CGFloat(clamped(index: state.previousItemIndex + itemCount))
        }
    }

    private func calculateItemScrollOffset(_ itemCount: Int) -> CGFloat {
        switch itemCount {
        case let count where count > 0:
            return floor(scrollOffset) + CGFloat(count) - scrollOffset
        case let count where count < 0:
            return ceil(scrollOffset) + CGFloat(count) - scrollOffset
        default:
            return round(scrollOffset) - scrollOffset
        }
    }

    func scrollToItem(at index: Int, duration: TimeInterval) {
        scrollTo(offset: CGFloat(index), duration: duration)
    }

    func scrollToItem(at index: Int, animated: Bool) {
        let duration = animated ? Constants.scrollDuration : 0
        scrollToItem(at: index, duration: duration)
    }
}

extension iCarousel {
    func removeItem(at index: Int, animated: Bool) {
        let clampedIndex = clamped(index: index)
        guard let itemView = itemView(at: clampedIndex) else { return }

        if animated {
            performAnimatedRemoval(itemView, at: clampedIndex)
        } else {
            performImmediateRemoval(itemView, at: clampedIndex)
        }
    }

    private func performAnimatedRemoval(_ itemView: UIView, at index: Int) {
        fadeOutItem(itemView) { [weak self] in
            self?.completeItemRemoval(itemView, at: index, animated: true)
        }
    }

    private func fadeOutItem(_ itemView: UIView, completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: 0.1,
            animations: {
                self.queue(itemView: itemView)
                itemView.itemCell?.layer.opacity = 0.0
            },
            completion: { _ in completion() }
        )
    }

    private func completeItemRemoval(_ itemView: UIView, at index: Int, animated: Bool) {
        itemView.itemCell?.removeFromSuperview()

        if animated {
            animateItemRemovalLayout(index)
        } else {
            updateLayoutAfterRemoval(index)
        }
    }

    private func animateItemRemovalLayout(_ index: Int) {
        UIView.animate(
            withDuration: Constants.insertDuration,
            delay: 0.1,
            animations: { [weak self] in
                self?.updateLayoutAfterRemoval(index)
            },
            completion: { [weak self] _ in
                self?.depthSortViews()
            }
        )
    }

    private func performImmediateRemoval(_ itemView: UIView, at index: Int) {
        transactionAnimated(false) { [weak self] in
            guard let self else { return }
            queue(itemView: itemView)
            itemView.itemCell?.removeFromSuperview()
            removeView(at: index)
            updateLayoutAfterRemoval(index)
            depthSortViews()
        }
    }

    private func updateLayoutAfterRemoval(_ index: Int) {
        removeView(at: index)
        numberOfItems -= 1
        isWrapEnabled = animator.isWrapEnabled
        updateNumberOfVisibleItems()
        _scrollOffset = CGFloat(currentItemIndex)
        didScroll()
    }

    func insertItem(at index: Int, animated: Bool) {
        prepareForInsertion()
        _ = performInsertion(at: index)

        if animated {
            animateInsertion()
        } else {
            completeInsertionImmediately()
        }

        handleScrollAdjustmentAfterInsertion(animated)
    }

    private func prepareForInsertion() {
        numberOfItems += 1
        isWrapEnabled = animator.isWrapEnabled
        updateNumberOfVisibleItems()
    }

    private func performInsertion(at index: Int) -> Int {
        let clampedIndex = clamped(index: index)
        insert(nil, at: clampedIndex)
        loadView(at: clampedIndex)
        updateItemWidthIfNeeded()
        return clampedIndex
    }

    private func updateItemWidthIfNeeded() {
        if abs(itemWidth) < Constants.floatErrorMargin {
            updateItemWidth()
        }
    }

    private func animateInsertion() {
        UIView.animate(
            withDuration: Constants.insertDuration,
            animations: { [weak self] in
                self?.transformItemViews()
            },
            completion: { [weak self] _ in
                self?.didScroll()
            }
        )
    }

    private func completeInsertionImmediately() {
        transactionAnimated(false) {
            didScroll()
        }
    }

    private func handleScrollAdjustmentAfterInsertion(_ animated: Bool) {
        if scrollOffset < 0 {
            let shouldAnimate = animated && numberOfPlaceholders > 0
            scrollToItem(at: 0, animated: shouldAnimate)
        }
    }

    func reloadItem(at index: Int, animated: Bool) {
        guard let containerView = itemView(at: index)?.itemCell else { return }

        if animated {
            addFadeTransition(to: containerView)
        }

        loadView(at: index, withContainerView: containerView)
    }

    private func addFadeTransition(to view: UIView) {
        let transition = CATransition()
        transition.duration = Constants.insertDuration
        transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
        transition.type = .fade
        view.layer.add(transition, forKey: nil)
    }
}

extension iCarousel {
    func clamped(offset: CGFloat) -> CGFloat {
        guard numberOfItems > 0 else { return -1.0 }

        let itemCount = CGFloat(numberOfItems)

        if isWrapEnabled {
            return calculateWrappedOffset(offset, itemCount: itemCount)
        } else {
            return calculateBoundedOffset(offset, itemCount: itemCount)
        }
    }

    private func calculateWrappedOffset(_ offset: CGFloat, itemCount: CGFloat) -> CGFloat {
        offset - floor(offset / itemCount) * itemCount
    }

    private func calculateBoundedOffset(_ offset: CGFloat, itemCount: CGFloat) -> CGFloat {
        let maxOffset = max(0, itemCount - 1)
        return min(max(0, offset), maxOffset)
    }

    func clamped(index: Int) -> Int {
        guard numberOfItems > 0 else { return -1 }

        if isWrapEnabled {
            return calculateWrappedIndex(index)
        } else {
            return calculateBoundedIndex(index)
        }
    }

    private func calculateWrappedIndex(_ index: Int) -> Int {
        let itemCount = CGFloat(numberOfItems)
        let indexFloat = CGFloat(index)
        let wrappedFloat = indexFloat - floor(indexFloat / itemCount) * itemCount
        return Int(wrappedFloat)
    }

    private func calculateBoundedIndex(_ index: Int) -> Int {
        let maxIndex = max(0, numberOfItems - 1)
        return min(max(0, index), maxIndex)
    }
}

extension iCarousel {
    func minScrollDistance<T>(from: T, to: T, numberOfItems: T) -> T
    where T: Comparable, T: SignedNumeric {
        let directDistance = to - from

        guard isWrapEnabled else { return directDistance }

        let wrappedDistance = calculateWrappedDistance(from: from, to: to, numberOfItems: numberOfItems)
        return chooseOptimalDistance(direct: directDistance, wrapped: wrappedDistance)
    }

    private func calculateWrappedDistance<T>(from: T, to: T, numberOfItems: T) -> T
    where T: Comparable, T: SignedNumeric {
        var distance = min(to, from) + numberOfItems - max(to, from)
        if from < to {
            distance = -distance
        }
        return distance
    }

    private func chooseOptimalDistance<T>(direct: T, wrapped: T) -> T
    where T: Comparable, T: SignedNumeric {
        abs(direct) <= abs(wrapped) ? direct : wrapped
    }

    func minScrollDistance(fromOffset: CGFloat, toOffset: CGFloat) -> CGFloat {
        minScrollDistance(from: fromOffset, to: toOffset, numberOfItems: CGFloat(numberOfItems))
    }

    func minScrollDistance(fromIndex: Int, toIndex: Int) -> Int {
        minScrollDistance(from: fromIndex, to: toIndex, numberOfItems: numberOfItems)
    }
}
