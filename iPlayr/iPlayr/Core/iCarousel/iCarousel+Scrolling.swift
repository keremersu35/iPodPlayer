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

    func scrollToItem(at index: Int, duration: TimeInterval) {
        scrollTo(offset: CGFloat(index), duration: duration)
    }

    func scrollToItem(at index: Int, animated: Bool) {
        let duration = animated ? Constants.scrollDuration : 0
        scrollToItem(at: index, duration: duration)
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
