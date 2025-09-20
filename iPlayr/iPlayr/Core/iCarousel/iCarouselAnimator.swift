import UIKit

extension iCarousel {
    @MainActor
    open class Animator {
        open var fadeMin: CGFloat = -.infinity
        open var fadeMax: CGFloat = .infinity
        open var fadeRange: CGFloat = 1.0
        open var fadeMinAlpha: CGFloat = 0.0
        open var spacing: CGFloat = 1.0
        open var isWrapEnabled: Bool = false
        open var offsetMultiplier: CGFloat = 1.0

        init() {
            configInit()
        }

        open func configInit() {}

        open func alphaForItem(with offset: CGFloat) -> CGFloat {
            let fadeFactor = calculateFadeFactor(for: offset)
            return calculateAlpha(from: fadeFactor)
        }

        private func calculateFadeFactor(for offset: CGFloat) -> CGFloat {
            if offset > fadeMax {
                return offset - fadeMax
            } else if offset < fadeMin {
                return fadeMin - offset
            }
            return 0
        }

        private func calculateAlpha(from factor: CGFloat) -> CGFloat {
            let clampedFactor = min(factor, fadeRange)
            let alphaReduction = clampedFactor / fadeRange * (1.0 - fadeMinAlpha)
            return 1.0 - alphaReduction
        }

        open func transformForItemView(with offset: CGFloat, in carousel: iCarousel) -> CATransform3D {
            let transform = createBaseTransform(for: carousel)
            return applyViewpointOffset(transform, carousel: carousel)
        }

        private func createBaseTransform(for carousel: iCarousel) -> CATransform3D {
            var transform = CATransform3DIdentity
            transform.m34 = carousel.perspective
            return transform
        }

        private func applyViewpointOffset(_ transform: CATransform3D, carousel: iCarousel) -> CATransform3D {
            let offset = carousel.viewpointOffset
            return CATransform3DTranslate(transform, -offset.width, -offset.height, 0.0)
        }

        final func _numberOfVisibleItems(in carousel: iCarousel) -> Int {
            let requestedCount = numberOfVisibleItems(in: carousel)
            let availableCount = totalItemCount(in: carousel)
            return max(0, min(requestedCount, availableCount))
        }

        open func numberOfVisibleItems(in carousel: iCarousel) -> Int {
            Constants.maxVisibleItems
        }
    }
}

extension iCarousel.Animator {
    func itemWidthWithSpacing(in carousel: iCarousel) -> CGFloat {
        carousel.itemWidth * spacing
    }

    func totalItemCount(in carousel: iCarousel) -> Int {
        carousel.numberOfItems + carousel.state.numberOfPlaceholdersToShow
    }
}

extension iCarousel.Animator {

    open class CoverFlow: iCarousel.Animator {
        open var tilt: CGFloat = 0.9
        let isCoverFlow2: Bool

        init(isCoverFlow2: Bool = false) {
            self.isCoverFlow2 = isCoverFlow2
            super.init()
        }

        open override func configInit() {
            super.configInit()
            spacing = 0.25
            offsetMultiplier = 2.0
        }

        func clampedOffset(_ offset: CGFloat, in carousel: iCarousel) -> CGFloat {
            if isCoverFlow2 {
                return calculateCoverFlow2Offset(offset, carousel: carousel)
            } else {
                return max(-1.0, min(1.0, offset))
            }
        }

        private func calculateCoverFlow2Offset(_ offset: CGFloat, carousel: iCarousel) -> CGFloat {
            let toggle = carousel.toggle
            var clampedOffset = max(-1.0, min(1.0, offset))

            if toggle > 0.0 {
                clampedOffset = calculatePositiveToggleOffset(offset, toggle: toggle)
            } else {
                clampedOffset = calculateNegativeToggleOffset(offset, toggle: toggle)
            }

            return clampedOffset
        }

        private func calculatePositiveToggleOffset(_ offset: CGFloat, toggle: CGFloat) -> CGFloat {
            if offset <= -0.5 {
                return -1.0
            } else if offset <= 0.5 {
                return -toggle
            } else if offset <= 1.5 {
                return 1.0 - toggle
            }
            return max(-1.0, min(1.0, offset))
        }

        private func calculateNegativeToggleOffset(_ offset: CGFloat, toggle: CGFloat) -> CGFloat {
            if offset > 0.5 {
                return 1.0
            } else if offset > -0.5 {
                return -toggle
            } else if offset > -1.5 {
                return -1.0 - toggle
            }
            return max(-1.0, min(1.0, offset))
        }

        open override func transformForItemView(with offset: CGFloat, in carousel: iCarousel) -> CATransform3D {
            let baseTransform = super.transformForItemView(with: offset, in: carousel)
            let coverFlowParams = calculateCoverFlowParameters(offset: offset, carousel: carousel)

            return applyCoverFlowTransform(baseTransform, params: coverFlowParams, carousel: carousel)
        }

        private func calculateCoverFlowParameters(offset: CGFloat, carousel: iCarousel) -> CoverFlowParams {
            let clampedOffset = clampedOffset(offset, in: carousel)
            let x = (clampedOffset * 0.5 * tilt + offset * spacing) * carousel.itemWidth
            let z = abs(clampedOffset) * -carousel.itemWidth * 0.5
            let angle = -clampedOffset * (CGFloat.pi / 2.0) * tilt

            return CoverFlowParams(x: x, z: z, angle: angle)
        }

        private struct CoverFlowParams {
            let x: CGFloat
            let z: CGFloat
            let angle: CGFloat
        }

        private func applyCoverFlowTransform(_ transform: CATransform3D, params: CoverFlowParams, carousel: iCarousel) -> CATransform3D {
            var translatedTransform: CATransform3D
            var rotatedTransform: CATransform3D

            if carousel.isVertical {
                translatedTransform = CATransform3DTranslate(transform, 0.0, params.x, params.z)
                rotatedTransform = CATransform3DRotate(translatedTransform, params.angle, -1.0, 0.0, 0.0)
            } else {
                translatedTransform = CATransform3DTranslate(transform, params.x, 0.0, params.z)
                rotatedTransform = CATransform3DRotate(translatedTransform, params.angle, 0.0, 1.0, 0.0)
            }

            return rotatedTransform
        }

        open override func numberOfVisibleItems(in carousel: iCarousel) -> Int {
            let carouselWidth = carousel.relativeWidth
            let itemWidth = itemWidthWithSpacing(in: carousel)
            let calculatedCount = Int(ceil(carouselWidth / itemWidth)) + 2

            return min(iCarousel.Constants.maxVisibleItems, calculatedCount)
        }
    }
}
