import UIKit

extension iCarousel {
    func setupGesture() {
        setupPanGesture()
        setupTapGesture()
    }

    private func setupPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        pan.delegate = self
        contentView.addGestureRecognizer(pan)
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
    }
}

extension iCarousel {
    @objc func didTap(_ tap: UITapGestureRecognizer) {
        let location = tap.location(in: contentView)

        guard let itemView = itemView(at: location),
              let index = index(of: itemView) else {
            scrollToCurrentItemIfNeeded()
            return
        }

        handleItemTap(at: index)
    }

    private func handleItemTap(at index: Int) {
        guard shouldSelectItem(at: index) else {
            handleScrollToCurrentItemIfNeeded()
            return
        }

        if shouldScrollToTappedItem(index) {
            scrollToItem(at: index, animated: true)
        }

        delegate?.carousel(self, didSelectItemAt: index)
    }

    private func shouldSelectItem(at index: Int) -> Bool {
        delegate?.carousel(self, shouldSelectItemAt: index) ?? true
    }

    private func shouldScrollToTappedItem(_ index: Int) -> Bool {
        (index != currentItemIndex && centerItemWhenSelected) ||
        (index == currentItemIndex && scrollToItemBoundary)
    }

    private func handleScrollToCurrentItemIfNeeded() {
        if isScrollEnabled && scrollToItemBoundary && canAutoscroll {
            scrollToCurrentItemIfNeeded()
        }
    }

    private func scrollToCurrentItemIfNeeded() {
        scrollToItem(at: currentItemIndex, animated: true)
    }
}

extension iCarousel {
    @objc func didPan(_ pan: UIPanGestureRecognizer) {
        guard canProcessPanGesture else { return }

        switch pan.state {
        case .began:
            handlePanBegan(pan)
        case .ended, .cancelled, .failed:
            handlePanEnded()
        case .changed:
            handlePanChanged(pan)
        case .possible:
            break
        default:
            break
        }
    }

    private var canProcessPanGesture: Bool {
        isScrollEnabled && numberOfItems > 0
    }

    private func handlePanBegan(_ pan: UIPanGestureRecognizer) {
        resetScrollingStates()
        setupInitialPanState(pan)
        notifyDragBegan()
    }

    private func resetScrollingStates() {
        isDragging = true
        isScrolling = false
        isDecelerating = false
    }

    private func setupInitialPanState(_ pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: self)
        state.previousTranslation = isVertical ? translation.y : translation.x
    }

    private func notifyDragBegan() {
        delegate?.carouselWillBeginDragging(self)
    }

    private func handlePanEnded() {
        isDragging = false
        state.didDrag = true

        if shouldDecelerate() {
            startDecelerationSequence()
        } else {
            handlePanEndedWithoutDeceleration()
        }
    }

    private func startDecelerationSequence() {
        state.didDrag = false
        startDecelerating()

        transactionAnimated(true) {
            delegate?.carouselDidEndDragging(self, willDecelerate: isDecelerating)
        }

        if isDecelerating {
            transactionAnimated(true) {
                delegate?.carouselWillBeginDecelerating(self)
            }
        }
    }

    private func handlePanEndedWithoutDeceleration() {
        transactionAnimated(true) {
            delegate?.carouselDidEndDragging(self, willDecelerate: false)
        }

        if isPagingEnabled {
            scrollToItem(at: currentItemIndex, animated: true)
            return
        }

        handleNonPagingPanEnd()
    }

    private func handleNonPagingPanEnd() {
        let shouldScrollToBoundary = (scrollToItemBoundary ||
                                    abs(scrollOffset - clamped(offset: scrollOffset)) > Constants.floatErrorMargin) &&
                                    !canAutoscroll

        guard shouldScrollToBoundary else {
            depthSortViews()
            return
        }

        if abs(scrollOffset - CGFloat(currentItemIndex)) < Constants.floatErrorMargin {
            scrollToItem(at: currentItemIndex, duration: 0.01)
        } else if shouldScroll() {
            let direction = Int(state.startVelocity / abs(state.startVelocity))
            scrollToItem(at: currentItemIndex + direction, animated: true)
        } else {
            scrollToItem(at: currentItemIndex, animated: true)
        }
    }

    private func handlePanChanged(_ pan: UIPanGestureRecognizer) {
        let translation = extractTranslation(from: pan)
        let velocity = extractVelocity(from: pan)
        let factor = calculateScrollFactor()

        updateScrollVelocity(velocity, factor: factor)
        updateScrollOffset(translation, factor: factor)
        updatePreviousTranslation(translation)

        didScroll()
    }

    private func extractTranslation(from pan: UIPanGestureRecognizer) -> CGFloat {
        let translation = pan.translation(in: self)
        return isVertical ? translation.y : translation.x
    }

    private func extractVelocity(from pan: UIPanGestureRecognizer) -> CGFloat {
        let velocity = pan.velocity(in: self)
        return isVertical ? velocity.y : velocity.x
    }

    private func calculateScrollFactor() -> CGFloat {
        guard !isWrapEnabled && bounces else { return 1.0 }

        let offsetDifference = abs(scrollOffset - clamped(offset: scrollOffset))
        return 1.0 - min(offsetDifference, bounceDistance) / bounceDistance
    }

    private func updateScrollVelocity(_ velocity: CGFloat, factor: CGFloat) {
        state.startVelocity = -velocity * factor * scrollSpeed / itemWidth
    }

    private func updateScrollOffset(_ translation: CGFloat, factor: CGFloat) {
        let translationDelta = translation - state.previousTranslation
        _scrollOffset -= translationDelta * factor * offsetMultiplier / itemWidth
    }

    private func updatePreviousTranslation(_ translation: CGFloat) {
        state.previousTranslation = translation
    }
}

extension iCarousel: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if isScrollEnabled {
            resetScrollingStatesForTouch()
        }

        return shouldProcessGestureTouch(gestureRecognizer, touch: touch)
    }

    private func resetScrollingStatesForTouch() {
        isDragging = false
        isScrolling = false
        isDecelerating = false
    }

    private func shouldProcessGestureTouch(_ gestureRecognizer: UIGestureRecognizer, touch: UITouch) -> Bool {
        switch gestureRecognizer {
        case _ as UITapGestureRecognizer:
            return shouldProcessTapTouch(touch)
        case _ as UIPanGestureRecognizer:
            return shouldProcessPanTouch(touch)
        default:
            return true
        }
    }

    private func shouldProcessTapTouch(_ touch: UITouch) -> Bool {
        var index = viewOrSuperviewIndex(touch.view)

        if index == nil && centerItemWhenSelected {
            index = viewOrSuperviewIndex(touch.view?.subviews.last)
        }

        if index != nil {
            return !viewImplementsTouchHandling(touch.view)
        }

        return true
    }

    private func viewImplementsTouchHandling(_ view: UIView?) -> Bool {
        viewOrSuperview(view, implementsSelector: #selector(touchesBegan(_:with:)))
    }

    private func shouldProcessPanTouch(_ touch: UITouch) -> Bool {
        guard isScrollEnabled else { return false }

        if viewOrSuperview(touch.view, implementsSelector: #selector(touchesMoved(_:with:))) {
            return shouldAllowPanOverExistingScrollHandling(touch)
        }

        return true
    }

    private func shouldAllowPanOverExistingScrollHandling(_ touch: UITouch) -> Bool {
        if let scrollView = viewOrSuperview(touch.view, UIScrollView.self) {
            return shouldAllowPanOverScrollView(scrollView)
        }

        if viewOrSuperview(touch.view, UIControl.self) != nil {
            return true
        }

        return false
    }

    private func shouldAllowPanOverScrollView(_ scrollView: UIScrollView) -> Bool {
        !scrollView.isScrollEnabled ||
        (isVertical && scrollView.contentSize.height <= scrollView.frame.size.height) ||
        (!isVertical && scrollView.contentSize.width <= scrollView.frame.size.width)
    }

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            return shouldBeginPanGesture(pan)
        }
        return true
    }

    private func shouldBeginPanGesture(_ pan: UIPanGestureRecognizer) -> Bool {
        guard ignorePerpendicularSwipes else { return true }

        let translation = pan.translation(in: self)
        return isVertical
            ? abs(translation.x) <= abs(translation.y)
            : abs(translation.x) >= abs(translation.y)
    }
}

extension iCarousel {
    func viewOrSuperviewIndex(_ view: UIView?) -> Int? {
        guard let view = view, view != contentView else { return nil }

        if let index = index(of: view) {
            return index
        }

        return viewOrSuperviewIndex(view.superview)
    }

    func viewOrSuperview(_ view: UIView?, implementsSelector selector: Selector) -> Bool {
        guard let view = view, view != contentView else { return false }

        if viewImplementsSelector(view, selector: selector) {
            return true
        }

        return viewOrSuperview(view.superview, implementsSelector: selector)
    }

    private func viewImplementsSelector(_ view: UIView, selector: Selector) -> Bool {
        var viewClass: AnyClass? = type(of: view)

        while let currentClass = viewClass, currentClass != UIView.self {
            if classImplementsSelector(currentClass, selector: selector) {
                return true
            }
            viewClass = currentClass.superclass()
        }

        return false
    }

    private func classImplementsSelector(_ viewClass: AnyClass, selector: Selector) -> Bool {
        var numberOfMethods: UInt32 = 0
        guard let methods = class_copyMethodList(viewClass, &numberOfMethods) else {
            return false
        }

        defer { free(methods) }

        for i in 0..<numberOfMethods {
            if method_getName(methods[Int(i)]) == selector {
                return true
            }
        }

        return false
    }

    func viewOrSuperview<T: UIView>(_ view: UIView?, _ type: T.Type) -> T? {
        guard let view = view, view != contentView else { return nil }

        if let result = view as? T {
            return result
        }

        return viewOrSuperview(view.superview, type)
    }
}
