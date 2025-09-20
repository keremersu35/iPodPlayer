import UIKit

extension iCarousel {
    func startAnimation() {
        guard timer == nil else { return }

        timer = createAnimationTimer()
        addTimerToRunLoops()
    }

    private func createAnimationTimer() -> Timer {
        Timer(timeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.performAnimationStep()
        }
    }

    private func addTimerToRunLoops() {
        guard let timer = timer else { return }
        [RunLoop.Mode.default, .tracking].forEach { mode in
            RunLoop.main.add(timer, forMode: mode)
        }
    }

    private func performAnimationStep() {
        transactionAnimated(false) { [weak self] in
            self?.step()
        }
    }

    func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

extension iCarousel {
    private struct PhysicsConfig {
        static let decelerationMultiplier = iCarousel.Constants.decelerationMultiplier
        static let scrollSpeedThreshold = iCarousel.Constants.scrollSpeedThreshold
        static let decelerateThreshold = iCarousel.Constants.decelerateThreshold
        static let scrollDistanceThreshold = iCarousel.Constants.scrollDistanceThreshold
    }

    func decelerationDistance() -> CGFloat {
        let acceleration = -state.startVelocity * PhysicsConfig.decelerationMultiplier * (1.0 - decelerationRate)
        return -pow(state.startVelocity, 2.0) / (2.0 * acceleration)
    }

    func shouldDecelerate() -> Bool {
        abs(state.startVelocity) > PhysicsConfig.scrollSpeedThreshold &&
        abs(decelerationDistance()) > PhysicsConfig.decelerateThreshold
    }

    func shouldScroll() -> Bool {
        abs(state.startVelocity) > PhysicsConfig.scrollSpeedThreshold &&
        abs(scrollOffset - CGFloat(currentItemIndex)) > PhysicsConfig.scrollDistanceThreshold
    }

    func startDecelerating() {
        let distance = calculateDecelerationDistance()
        setupDecelerationTiming(distance: distance)

        if distance != 0.0 {
            isDecelerating = true
            startAnimation()
        }
    }

    private func calculateDecelerationDistance() -> CGFloat {
        let distance = decelerationDistance()
        state.startOffset = scrollOffset
        state.endOffset = state.startOffset + distance

        applyBoundaryConstraints()

        return state.endOffset - state.startOffset
    }

    private func applyBoundaryConstraints() {
        if isPagingEnabled {
            state.endOffset = state.endOffset > state.startOffset ? ceil(state.startOffset) : floor(state.startOffset)
        } else if stopAtItemBoundary {
            state.endOffset = state.endOffset > state.startOffset ? ceil(state.endOffset) : floor(state.endOffset)
        }

        if !isWrapEnabled {
            applyScrollLimits()
        }
    }

    private func applyScrollLimits() {
        if bounces {
            let bounds = bounceScrollBounds
            state.endOffset = max(bounds.min, min(bounds.max, state.endOffset))
        } else {
            state.endOffset = clamped(offset: state.endOffset)
        }
    }

    private var bounceScrollBounds: (min: CGFloat, max: CGFloat) {
        let minBound = -bounceDistance
        let maxBound = CGFloat(numberOfItems) - 1.0 + bounceDistance
        return (min: minBound, max: maxBound)
    }

    private func setupDecelerationTiming(distance: CGFloat) {
        state.startTime = CACurrentMediaTime()
        state.scrollDuration = TimeInterval(abs(distance) / abs(0.5 * state.startVelocity))
    }

    func easeInOut(time: CGFloat) -> CGFloat {
        let doubleTime = time * 2.0
        return time < 0.5
            ? 0.5 * pow(doubleTime, 3.0)
            : 0.5 * pow(doubleTime - 2.0, 3.0) + 1.0
    }
}

extension iCarousel {
    private enum AnimationState {
        case scrolling
        case decelerating
        case autoscrolling
        case toggling
        case idle
    }

    private var currentAnimationState: AnimationState {
        if isScrolling && !isDragging { return .scrolling }
        if isDecelerating { return .decelerating }
        if canAutoscroll && !isDragging { return .autoscrolling }
        if abs(toggle) > Constants.floatErrorMargin { return .toggling }
        return .idle
    }

    @objc private func step() {
        updateTimestamp()

        switch currentAnimationState {
        case .scrolling:
            handleScrollingAnimation()
        case .decelerating:
            handleDecelerationAnimation()
        case .autoscrolling:
            handleAutoscrollAnimation()
        case .toggling:
            handleToggleAnimation()
        case .idle:
            if !canAutoscroll { stopAnimation() }
        }
    }

    private func updateTimestamp() {
        state.lastTime = CACurrentMediaTime()
    }

    private func handleScrollingAnimation() {
        let progress = calculateScrollProgress()
        let easedProgress = easeInOut(time: progress)

        _scrollOffset = state.startOffset + (state.endOffset - state.startOffset) * easedProgress
        didScroll()

        if progress >= 1.0 {
            completeScrollingAnimation()
        }
    }

    private func calculateScrollProgress() -> CGFloat {
        CGFloat(min(1.0, (CACurrentMediaTime() - state.startTime) / state.scrollDuration))
    }

    private func completeScrollingAnimation() {
        isScrolling = false
        depthSortViews()
        transactionAnimated(true) {
            delegate?.carouselDidEndScrollingAnimation(self)
        }
    }

    private func handleDecelerationAnimation() {
        let currentTime = CACurrentMediaTime()
        let scrollDuration = CGFloat(state.scrollDuration)
        let time = min(scrollDuration, CGFloat(currentTime - state.startTime))

        let acceleration = -state.startVelocity / scrollDuration
        let distance = state.startVelocity * time + 0.5 * acceleration * pow(time, 2.0)

        _scrollOffset = state.startOffset + distance
        didScroll()

        if abs(time - scrollDuration) < Constants.floatErrorMargin {
            completeDecelerationAnimation(currentTime: currentTime)
        }
    }

    private func completeDecelerationAnimation(currentTime: TimeInterval) {
        isDecelerating = false
        transactionAnimated(true) {
            delegate?.carouselDidEndDecelerating(self)
        }

        handlePostDecelerationBehavior(currentTime: currentTime)
    }

    private func handlePostDecelerationBehavior(currentTime: TimeInterval) {
        let shouldScrollToBoundary = (scrollToItemBoundary ||
                                    abs(scrollOffset - clamped(offset: scrollOffset)) > Constants.floatErrorMargin) &&
                                    !canAutoscroll

        if shouldScrollToBoundary {
            scrollToNearestItem()
        } else {
            setupToggleAnimation(currentTime: currentTime)
        }
    }

    private func scrollToNearestItem() {
        let targetIndex = currentItemIndex
        let scrollDuration: TimeInterval = abs(scrollOffset - CGFloat(targetIndex)) < Constants.floatErrorMargin ? 0.01 : 0.4

        scrollToItem(at: targetIndex, duration: scrollDuration)
    }

    private func setupToggleAnimation(currentTime: TimeInterval) {
        var difference = round(scrollOffset) - scrollOffset

        if difference > 0.5 {
            difference -= 1.0
        } else if difference < -0.5 {
            difference += 1.0
        }

        let maxToggleDuration = Constants.maxToggleDuration
        state.toggleTime = currentTime - TimeInterval(maxToggleDuration * abs(difference))
        toggle = max(-1.0, min(1.0, -difference))
    }

    private func handleAutoscrollAnimation() {
        let delta = CGFloat(CACurrentMediaTime() - state.lastTime)

        if isPagingEnabled {
            handlePagingAutoscroll(delta: delta)
        } else {
            handleContinuousAutoscroll(delta: delta)
        }
    }

    private func handlePagingAutoscroll(delta: CGFloat) {
        state.tempOnePageValue += delta * autoscroll

        if abs(state.tempOnePageValue) >= 1 {
            let direction = max(-1, min(1, state.tempOnePageValue))
            let targetOffset = clamped(offset: scrollOffset - direction)
            state.tempOnePageValue = 0
            scrollToItem(at: Int(targetOffset), animated: true)
        }
    }

    private func handleContinuousAutoscroll(delta: CGFloat) {
        if state.tempOnePageValue != 0 {
            state.tempOnePageValue = 0
        }
        scrollOffset = clamped(offset: scrollOffset - delta * autoscroll)
    }

    private func handleToggleAnimation() {
        let currentTime = CACurrentMediaTime()
        let toggleDuration = calculateToggleDuration()
        let progress = min(1.0, CGFloat(currentTime - state.toggleTime) / toggleDuration)
        let easedProgress = easeInOut(time: progress)

        toggle = toggle < 0.0 ? (easedProgress - 1.0) : (1.0 - easedProgress)
        didScroll()
    }

    private func calculateToggleDuration() -> TimeInterval {
        let baseDuration = state.startVelocity > 0 ? min(1.0, max(0.0, 1.0 / abs(state.startVelocity))) : 1.0
        let minDuration = Constants.minToggleDuration
        let maxDuration = Constants.maxToggleDuration

        return minDuration + (maxDuration - minDuration) * baseDuration
    }
}

extension iCarousel {
    func didScroll() {
        applyScrollConstraints()
        handleItemTransition()
        updateViewsAndNotifyDelegates()
        updateScrollState()
    }

    private func applyScrollConstraints() {
        if isWrapEnabled || !bounces {
            _scrollOffset = clamped(offset: scrollOffset)
        } else {
            applyBounceConstraints()
        }
    }

    private func applyBounceConstraints() {
        let bounds = normalScrollBounds

        if scrollOffset < bounds.min {
            _scrollOffset = bounds.min
            state.startVelocity = 0.0
        } else if scrollOffset > bounds.max {
            _scrollOffset = bounds.max
            state.startVelocity = 0.0
        }
    }

    private var normalScrollBounds: (min: CGFloat, max: CGFloat) {
        let minBound = -bounceDistance
        let maxBound = max(CGFloat(numberOfItems) - 1, 0.0) + bounceDistance
        return (min: minBound, max: maxBound)
    }

    private func handleItemTransition() {
        let difference = minScrollDistance(fromIndex: currentItemIndex, toIndex: state.previousItemIndex)

        if difference != 0 {
            state.toggleTime = CACurrentMediaTime()
            toggle = CGFloat(max(-1, min(1, difference)))
            startAnimation()
        }
    }

    private func updateViewsAndNotifyDelegates() {
        loadUnloadViews()
        transformItemViews()

        notifyScrollDelegates()
        notifyItemChangeDelegates()
    }

    private func notifyScrollDelegates() {
        let hasScrollChanged = abs(scrollOffset - state.previousScrollOffset) > Constants.floatErrorMargin

        if hasScrollChanged {
            transactionAnimated(true) {
                delegate?.carouselDidScroll(self)
            }
        }
    }

    private func notifyItemChangeDelegates() {
        let hasItemChanged = state.previousItemIndex != currentItemIndex

        if hasItemChanged {
            transactionAnimated(true) {
                delegate?.carouselCurrentItemIndexDidChange(self)
            }
        }
    }

    private func updateScrollState() {
        state.previousScrollOffset = _scrollOffset
        state.previousItemIndex = currentItemIndex
    }
}

extension iCarousel {
    @discardableResult
    func transactionAnimated<T>(_ enabled: Bool, _ closure: () -> T) -> T {
        CATransaction.begin()
        CATransaction.setDisableActions(!enabled)
        defer { CATransaction.commit() }
        return closure()
    }
}
