import UIKit

extension iCarousel.Animator {
    func wrapEnabled(_ wrapEnabled: Bool) -> Self {
        isWrapEnabled = wrapEnabled
        return self
    }

    func offsetMultiplier(_ offsetMultiplier: CGFloat) -> Self {
        self.offsetMultiplier = offsetMultiplier
        return self
    }

    func spacing(_ spacing: CGFloat) -> Self {
        self.spacing = spacing
        return self
    }
}
