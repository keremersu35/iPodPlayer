import UIKit

extension iCarousel {
    func queue(itemView view: UIView) {
        itemViewPool.insert(view)
    }
    
    func queue(placeholderView view: UIView) {
        placeholderViewPool.insert(view)
    }
    
    func queue(_ view: UIView, at index: Int) {
        if index < 0 || index >= numberOfItems {
            queue(placeholderView: view)
        } else {
            queue(itemView: view)
        }
    }
    
    func dequeueItemView() -> UIView? {
        itemViewPool.popFirst()
    }
    
    func dequeuePlaceholderView() -> UIView? {
        placeholderViewPool.popFirst()
    }
}
