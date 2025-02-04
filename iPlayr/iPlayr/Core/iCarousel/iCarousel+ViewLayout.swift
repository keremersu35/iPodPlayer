import UIKit

extension iCarousel {
    func compareViewDepth(view1: ItemCell, view2: ItemCell) -> Bool {
        let t1 = view1.layer.transform
        let t2 = view2.layer.transform
        let z1 = t1.m13 + t1.m23 + t1.m33 + t1.m43
        let z2 = t2.m13 + t2.m23 + t2.m33 + t2.m43
        var difference = z1 - z2
        if difference == 0, let currentItemCell = self.currentItemView?.itemCell {
            let t3 = currentItemCell.layer.transform
            if self.isVertical {
                let y1 = t1.m12 + t1.m22 + t1.m32 + t1.m42
                let y2 = t2.m12 + t2.m22 + t2.m32 + t2.m42
                let y3 = t3.m12 + t3.m22 + t3.m32 + t3.m42
                difference = abs(y2 - y3) - abs(y1 - y3)
            } else {
                let x1 = t1.m11 + t1.m21 + t1.m31 + t1.m41
                let x2 = t2.m11 + t2.m21 + t2.m31 + t2.m41
                let x3 = t3.m11 + t3.m21 + t3.m31 + t3.m41
                difference = abs(x2 - x3) - abs(x1 - x3)
            }
        }
        return difference < 0
    }
    func depthSortViews() {
        itemViews.values.compactMap {$0.itemCell}.sorted(by: compareViewDepth).forEach { (view) in
            contentView.bringSubviewToFront(view)
        }
    }
}
extension iCarousel {
    /// 计算相对于当前Item的偏移量
    public func offsetForItem(at index: Int) -> CGFloat {
        // calculate relative position
        var offset = CGFloat(index) - scrollOffset
        if isWrapEnabled {
            let numberOfItems = CGFloat(self.numberOfItems)
            if offset > numberOfItems / 2.0 {
                offset -= numberOfItems
            } else if offset < -numberOfItems / 2.0 {
                offset += numberOfItems
            }
        }
        return offset
    }
}
extension iCarousel {
    func transformItemView(_ itemView: UIView, at index: Int) {
        let offset = offsetForItem(at: index)

        guard let cell = itemView.itemCell else {
            itemView.layoutIfNeeded()
            return
        }
        cell.layer.opacity = Float(animator.alphaForItem(with: offset))
        cell.center = CGPoint(x: self.bounds.size.width/2.0 + contentOffset.width,
                                       y: self.bounds.size.height/2.0 + contentOffset.height)
        cell.isUserInteractionEnabled = (!centerItemWhenSelected || index == self.currentItemIndex)
        cell.layer.rasterizationScale = UIScreen.main.scale

        itemView.layoutIfNeeded()

        let clampedOffset = max(-1.0, min(1.0, offset))
        if isDecelerating ||
            (isScrolling && !isDragging && !state.didDrag) ||
            (canAutoscroll && !isDragging) ||
            (!isWrapEnabled && (scrollOffset < 0 || scrollOffset >= CGFloat(numberOfItems - 1))) {
            if offset > 0 {
                toggle = offset <= 0.5 ? -clampedOffset : (1.0 - clampedOffset)
            } else {
                toggle = offset > -0.5 ? -clampedOffset : (-1.0 - clampedOffset)
            }
        }

        let transform = animator.transformForItemView(with: offset, in: self)
        cell.layer.transform = transform

        var showBackfaces = itemView.layer.isDoubleSided
        if showBackfaces {
            showBackfaces = animator.showBackfaces(view: itemView, in: self)
        }
        cell.isHidden = !(showBackfaces ? showBackfaces : (transform.m33 > 0.0))
    }
    
    func transformItemViews() {
        itemViews.forEach { transformItemView($0.value, at: $0.key) }
    }
}

extension iCarousel {
    func updateItemWidth() {
        if let itemWidth = delegate?.carouselItemWidth(self), itemWidth > 0 {
            self.itemWidth = itemWidth
        }
        if numberOfItems > 0 {
            if itemViews.isEmpty {
                loadView(at: 0)
            }
        } else if numberOfPlaceholders > 0 {
            if itemViews.isEmpty {
                loadView(at: -1)
            }
        }
    }
    
    func updateNumberOfVisibleItems() {
        numberOfVisibleItems = animator._numberOfVisibleItems(in: self)
    }
    
    func layOutItemViews() {
        if dataSource == nil {
            return
        }
        isWrapEnabled = animator.isWrapEnabled
        state.numberOfPlaceholdersToShow = isWrapEnabled ? 0 : numberOfPlaceholders
        updateItemWidth()
        updateNumberOfVisibleItems()
        state.previousScrollOffset = self.scrollOffset
        offsetMultiplier = animator.offsetMultiplier
        if !isScrolling && !isDecelerating && !canAutoscroll {
            if scrollToItemBoundary && self.currentItemIndex != -1 {
                scrollToItem(at: self.currentItemIndex, animated: true)
            } else {
                _scrollOffset = clamped(offset: scrollOffset)
            }
        }
        didScroll()
    }
}

extension iCarousel {
    var relativeWidth: CGFloat {
        _relativeWidth(self.isVertical)
    }
}

extension UIView {
    func _relativeWidth(_ isVertical: Bool) -> CGFloat {
        isVertical ? bounds.size.height : bounds.size.width
    }
}
