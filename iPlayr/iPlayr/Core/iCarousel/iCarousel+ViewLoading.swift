import UIKit

extension iCarousel {
    class ItemCell: UIView {
        let index: Int
        var child: UIView {
            didSet {
                oldValue.removeFromSuperview()
                self.addSubview(self.child)
                setNeedsLayout()
            }
        }
        init(child: UIView, index: Int, frame: CGRect = .zero) {
            self.child = child
            self.index = index
            super.init(frame: frame)
            self.addSubview(child)
            self.layer.opacity = 0
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            child.frame.origin.x = (self.bounds.size.width - child.frame.size.width) / 2.0
            child.frame.origin.y = (self.bounds.size.height - child.frame.size.height) / 2.0
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
            let view: UIView = createView(at: index)
            setItemView(view, forIndex: index)
            if let containerView = containerView {
                // set container frame
                if isVertical {
                    containerView.bounds.size.width = view.frame.size.width
                    containerView.bounds.size.height = min(itemWidth, view.frame.size.height)
                } else {
                    containerView.bounds.size.width = min(itemWidth, view.frame.size.width)
                    containerView.bounds.size.height = view.frame.size.height
                }
                queue(containerView.child, at: index)
                containerView.child = view
            } else {
                contentView.addSubview(self.createItemCell(view, index: index))
            }
            view.itemCell?.layer.opacity = 0.0
            transformItemView(view, at: index)
            return view
        }
    }
    
    func loadUnloadViews() {
        updateItemWidth()
        updateNumberOfVisibleItems()
        var visibleIndices = Set<Int>()
        var offset = self.currentItemIndex - numberOfVisibleItems / 2
        if !isWrapEnabled {
            let minV = -Int(ceil(CGFloat(state.numberOfPlaceholdersToShow) / 2.0))
            let maxV = numberOfItems - 1 + state.numberOfPlaceholdersToShow / 2
            offset = max(minV, min(maxV - numberOfVisibleItems + 1, offset))
        }
        (0..<numberOfVisibleItems).forEach { (i) in
            var index = i + offset
            if isWrapEnabled {
                index = clamped(index: index)
            }
            let alpha = animator.alphaForItem(with: offsetForItem(at: index))
            if alpha > 0 {
                visibleIndices.insert(index)
            }
        }
        itemViews.forEach { (number, view) in
            guard !visibleIndices.contains(number) else {
                visibleIndices.remove(number)
                return
            }
            queue(view, at: number)
            view.itemCell?.removeFromSuperview()
            itemViews[number] = nil
        }
        visibleIndices.forEach { (number) in
            if itemViews[number] == nil {
                loadView(at: number)
            }
        }
    }
    
    func reloadData() {
        itemViews.values.forEach { (view) in
            view.itemCell?.removeFromSuperview()
        }
        guard let dataSource = dataSource else { return }
        numberOfVisibleItems = 0
        numberOfItems = dataSource.numberOfItems(in: self)
        numberOfPlaceholders = dataSource.numberOfPlaceholders(in: self)
        itemViews = [:]
        itemViewPool = []
        placeholderViewPool = []
        setNeedsLayout()
        if numberOfItems > 0 && scrollOffset < 0.0 {
            scrollToItem(at: 0, animated: numberOfPlaceholders > 0)
        }
    }
}

extension iCarousel {
    func createItemCell(_ view: UIView, index: Int) -> ItemCell {
        if itemWidth <= 0 {
            itemWidth = view._relativeWidth(isVertical)
        }
        var frame = view.bounds
        frame.size.width = isVertical ? frame.size.width : itemWidth
        frame.size.height = isVertical ? itemWidth: frame.size.height
        let containerView = ItemCell(child: view, index: index, frame: frame)

        return containerView
    }
    private func createView(at index: Int) -> UIView {
        let view: UIView?
        if index < 0 {
            let index = Int(ceil(CGFloat(state.numberOfPlaceholdersToShow) / 2.0)) + index
            view = dataSource?.carousel(self, placeholderViewAt: index, reusingView: self.dequeuePlaceholderView())
        } else if index >= numberOfItems {
            let index = Int(CGFloat(state.numberOfPlaceholdersToShow) / 2.0) + index - numberOfItems
            view = dataSource?.carousel(self, placeholderViewAt: index, reusingView: self.dequeuePlaceholderView())
        } else {
            view = dataSource?.carousel(self, viewForItemAt: index, reusingView: self.dequeueItemView())
        }
        return view ?? UIView()
    }
}
