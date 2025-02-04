import UIKit

extension iCarousel {
    open class Animator {
        open internal(set) var fadeMin: CGFloat = -.infinity
        open internal(set) var fadeMax: CGFloat = .infinity
        open internal(set) var fadeRange: CGFloat = 1.0
        open internal(set) var fadeMinAlpha: CGFloat = 0.0
        open internal(set) var spacing: CGFloat = 1.0
        open internal(set) var arc: CGFloat = .pi * 2.0
        open internal(set) var isWrapEnabled: Bool = false
        open internal(set) var offsetMultiplier: CGFloat = 1.0
        public init() {
            configInit()
        }
        open func configInit() {}
        open func alphaForItem(with offset: CGFloat) -> CGFloat {
            let factor: CGFloat
            if offset > fadeMax {
                factor = offset - fadeMax
            } else if offset < fadeMin {
                factor = fadeMin - offset
            } else {
                factor = 0
            }
            return 1.0 - min(factor, fadeRange) / fadeRange * (1.0 - fadeMinAlpha)
        }
        open func transformForItemView(with offset: CGFloat, in carousel: iCarousel) -> CATransform3D {
            var transform: CATransform3D = CATransform3DIdentity
            transform.m34 = carousel.perspective
            transform = CATransform3DTranslate(transform, -carousel.viewpointOffset.width, -carousel.viewpointOffset.height, 0.0)
            return transform
        }
        open func showBackfaces(view: UIView, in carousel: iCarousel) -> Bool {
            true
        }
        open func circularCarouselItemCount(in carousel: iCarousel) -> Int {
            _count1(in: carousel)
        }
        final func _numberOfVisibleItems(in carousel: iCarousel) -> Int {
            max(0, min(numberOfVisibleItems(in: carousel), _count1(in: carousel)))
        }
        open func numberOfVisibleItems(in carousel: iCarousel) -> Int {
            iCarousel.global.maxVisibleItems
        }
    }
    open class CanBeInvertedAnimator: Animator {
        public let inverted: Bool
        public init(inverted: Bool = false) {
            self.inverted = inverted
            super.init()
        }
    }
}
extension iCarousel.Animator {
    public func itemWidthWithSpacing(in carousel: iCarousel) -> CGFloat {
        carousel.itemWidth * spacing
    }
    public func _count1(in carousel: iCarousel) -> Int {
        carousel.numberOfItems + carousel.state.numberOfPlaceholdersToShow
    }
    public func _count2(in carousel: iCarousel) -> Int {
        let width = carousel.relativeWidth
        var count = Int(ceil(width / itemWidthWithSpacing(in: carousel)) * CGFloat.pi)
        count = min(iCarousel.global.maxVisibleItems, max(12, count))
        count = min(_count1(in: carousel), count)
        return count
    }
}
// MARK: -
extension iCarousel.Animator {
    open class Linear: iCarousel.Animator {
        open override func transformForItemView(with offset: CGFloat, in carousel: iCarousel) -> CATransform3D {
            let transform = super.transformForItemView(with: offset, in: carousel)
            let t1: CGFloat = offset * itemWidthWithSpacing(in: carousel)
            if carousel.isVertical {
                return CATransform3DTranslate(transform, 0.0, t1, 0.0)
            } else {
                return CATransform3DTranslate(transform, t1, 0.0, 0.0)
            }
        }
        open override func numberOfVisibleItems(in carousel: iCarousel) -> Int {
            let width = carousel.relativeWidth
            let itemWidth = itemWidthWithSpacing(in: carousel)
            if itemWidth <= 0 {
                return 0
            }
            let numberOfVisibleItems = Int(ceil(width / itemWidth)) + 2
            return min(iCarousel.global.maxVisibleItems, numberOfVisibleItems)
        }
    }
    open class Rotary: iCarousel.CanBeInvertedAnimator {
        open override func configInit() {
            super.configInit()
            isWrapEnabled = true
        }
        open override func circularCarouselItemCount(in carousel: iCarousel) -> Int {
            _count2(in: carousel)
        }
        open override func transformForItemView(with offset: CGFloat, in carousel: iCarousel) -> CATransform3D {
            let transform = super.transformForItemView(with: offset, in: carousel)
            let count = CGFloat(circularCarouselItemCount(in: carousel))
            var radius = max(
                itemWidthWithSpacing(in: carousel) / 2,
                itemWidthWithSpacing(in: carousel) / 2 / tan(arc / 2.0 / count))
            var angle = offset * arc / count
            if inverted {
                radius = -radius
                angle = -angle
            }
            if carousel.isVertical {
                return CATransform3DTranslate(transform, 0.0, radius * sin(angle), radius * cos(angle) - radius)
            } else {
                return CATransform3DTranslate(transform, radius * sin(angle), 0.0, radius * cos(angle) - radius)
            }
        }
        open override func numberOfVisibleItems(in carousel: iCarousel) -> Int {
            let numberOfVisibleItems: Int
            if inverted {
                numberOfVisibleItems = Int(circularCarouselItemCount(in: carousel) / 2)
            } else {
                numberOfVisibleItems = Int(circularCarouselItemCount(in: carousel))
            }
            return min(iCarousel.global.maxVisibleItems, numberOfVisibleItems)
        }
    }
    
    open class CoverFlow: iCarousel.Animator {
        open internal(set) var tilt: CGFloat = 0.9
        public let isCoverFlow2: Bool
        public init(isCoverFlow2: Bool = false) {
            self.isCoverFlow2 = isCoverFlow2
            super.init()
        }
        open override func configInit() {
            super.configInit()
            spacing = 0.25
            offsetMultiplier = 2.0
        }
        func clampedOffset(_ offset: CGFloat, in carousel: iCarousel) -> CGFloat {
            var clampedOffset = max(-1.0, min(1.0, offset))
            if isCoverFlow2 {
                let toggle = carousel.toggle
                if toggle > 0.0 {
                    if offset <= -0.5 {
                        clampedOffset = -1.0
                    } else if offset <= 0.5 {
                        clampedOffset = -toggle
                    } else if offset <= 1.5 {
                        clampedOffset = 1.0 - toggle
                    }
                } else {
                    if offset > 0.5 {
                        clampedOffset = 1.0
                    } else if offset > -0.5 {
                        clampedOffset = -toggle
                    } else if offset > -1.5 {
                        clampedOffset = -1.0 - toggle
                    }
                }
            }
            return clampedOffset
        }
        open override func transformForItemView(with offset: CGFloat, in carousel: iCarousel) -> CATransform3D {
            var transform = super.transformForItemView(with: offset, in: carousel)
            let clampedOffset = self.clampedOffset(offset, in: carousel)
            let x = (clampedOffset * 0.5 * tilt + offset * spacing) * carousel.itemWidth
            let z = abs(clampedOffset) * -carousel.itemWidth * 0.5
            let pi_2 = CGFloat.pi / 2.0
            let angle = -clampedOffset * pi_2 * tilt
            if carousel.isVertical {
                transform = CATransform3DTranslate(transform, 0.0, x, z)
                return CATransform3DRotate(transform, angle, -1.0, 0.0, 0.0)
            } else {
                transform = CATransform3DTranslate(transform, x, 0.0, z)
                return CATransform3DRotate(transform, angle, 0.0, 1.0, 0.0)
            }
        }
        open override func numberOfVisibleItems(in carousel: iCarousel) -> Int {
            let width = carousel.relativeWidth
            let itemWidth = itemWidthWithSpacing(in: carousel)
            let numberOfVisibleItems = Int(ceil(width / itemWidth)) + 2
            return min(iCarousel.global.maxVisibleItems, numberOfVisibleItems)
        }
    }
    open class TimeMachine: iCarousel.CanBeInvertedAnimator {
        open internal(set) var tilt: CGFloat = 0.3
        open override func configInit() {
            super.configInit()
            if inverted {
                fadeMin = 0.0
            } else {
                fadeMax = 0.0
            }
        }
        open override func transformForItemView(with offset: CGFloat, in carousel: iCarousel) -> CATransform3D {
            let transform = super.transformForItemView(with: offset, in: carousel)
            var tilt = self.tilt
            var offset = offset
            if inverted {
                tilt = -tilt
                offset = -offset
            }
            let t1 = offset * carousel.itemWidth * tilt
            let t2 = offset * itemWidthWithSpacing(in: carousel)
            if carousel.isVertical {
                return CATransform3DTranslate(transform, 0.0, t1, t2)
            } else {
                return CATransform3DTranslate(transform, t1, 0.0, t2)
            }
        }
    }
}
