import UIKit

protocol iCarouselDataSource: AnyObject {
    func numberOfItems() -> Int
    func carousel(viewForItemAt index: Int) -> UIView
    func numberOfPlaceholders(in carousel: iCarousel) -> Int
    func carousel(_ carousel: iCarousel, placeholderViewAt index: Int, reusingView: UIView?) -> UIView?
}

extension iCarouselDataSource {
    func numberOfPlaceholders(in carousel: iCarousel) -> Int { 0 }
    func carousel(_ carousel: iCarousel, placeholderViewAt index: Int, reusingView: UIView?) -> UIView? { nil }
}
