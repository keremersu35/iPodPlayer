import UIKit

public protocol iCarouselDataSource: AnyObject {
    func numberOfItems(in carousel: iCarousel) -> Int
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusingView: UIView?) -> UIView
    func numberOfPlaceholders(in carousel: iCarousel) -> Int
    func carousel(_ carousel: iCarousel, placeholderViewAt index: Int, reusingView: UIView?) -> UIView?
}

public extension iCarouselDataSource {
    func numberOfPlaceholders(in carousel: iCarousel) -> Int { 0 }
    func carousel(_ carousel: iCarousel, placeholderViewAt index: Int, reusingView: UIView?) -> UIView? { nil }
}
