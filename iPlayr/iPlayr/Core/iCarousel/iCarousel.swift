import UIKit

extension iCarousel {
    enum Constants {
        static let minToggleDuration: CGFloat = 0.2
        static let maxToggleDuration: CGFloat = 0.4
        static let scrollDuration: TimeInterval = 0.4
        static let insertDuration: TimeInterval = 0.4
        static let decelerateThreshold: CGFloat = 0.1
        static let scrollSpeedThreshold: CGFloat = 2.0
        static let scrollDistanceThreshold: CGFloat = 0.1
        static let decelerationMultiplier: CGFloat = 30.0
        static let floatErrorMargin: CGFloat = 0.000001
        static let maxVisibleItems: Int = 30
    }
}

public final class iCarousel: UIView {
    struct State {
        var startTime: TimeInterval = 0
        var lastTime: TimeInterval = 0
        var startOffset: CGFloat = .zero
        var endOffset: CGFloat = .zero
        var scrollDuration: TimeInterval = 0
        var previousItemIndex: Int = 0
        var previousScrollOffset: CGFloat = 0
        var numberOfPlaceholdersToShow: Int = 0
        var startVelocity: CGFloat = 0
        var toggleTime: TimeInterval = 0
        var previousTranslation: CGFloat = 0
        var didDrag: Bool = false
        var tempOnePageValue: CGFloat = 0
    }
    internal var state: State = State()
    internal var itemViewPool: Set<UIView> = []
    internal var placeholderViewPool: Set<UIView> = []
    internal var itemViews: [Int: UIView] = [:]
    internal var timer: Timer?

    weak var dataSource: iCarouselDataSource? {
        didSet {
            if dataSource !== oldValue && dataSource != nil {
                reloadData()
            }
        }
    }

    weak var delegate: iCarouselDelegate? {
        didSet {
            if delegate !== oldValue && delegate != nil && dataSource != nil {
                reloadData()
            }
        }
    }

    var animator: iCarousel.Animator = .Linear() {
        didSet {
            if animator !== oldValue {
                layOutItemViews()
            }
        }
    }
    var perspective: CGFloat = -1.0/500.0 {
        didSet {
            transformItemViews()
        }
    }

    var decelerationRate: CGFloat = 0.95
    var scrollSpeed: CGFloat = 1.0
    var bounceDistance: CGFloat = 1.0

    var isScrollEnabled: Bool = true
    var isPagingEnabled: Bool = false
    var isVertical: Bool = false {
        didSet {
            if isVertical != oldValue {
                layOutItemViews()
            }
        }
    }

    var isWrapEnabled: Bool = false
    var bounces: Bool = true
    internal var _scrollOffset: CGFloat = .zero
    var scrollOffset: CGFloat {
        get { _scrollOffset }
        set { changeScrollOffset(newValue) }
    }
    var offsetMultiplier: CGFloat = 1.0
    var contentOffset: CGSize = .zero {
        didSet {
            if contentOffset != oldValue {
                layOutItemViews()
            }
        }
    }
    var viewpointOffset: CGSize = .zero {
        didSet {
            if viewpointOffset != oldValue {
                transformItemViews()
            }
        }
    }
    var numberOfItems: Int = 0
    var numberOfPlaceholders: Int = 0

    var numberOfVisibleItems: Int = 0
    var itemWidth: CGFloat = 0
    var toggle: CGFloat = 0
    var autoscroll: CGFloat = 0 {
        didSet {
            if canAutoscroll {
                startAnimation()
            }
        }
    }
    internal var canAutoscroll: Bool {
        return autoscroll != 0
    }
    var stopAtItemBoundary: Bool = true
    var scrollToItemBoundary: Bool = true
    var ignorePerpendicularSwipes: Bool = true
    var centerItemWhenSelected: Bool = true

    var isDragging: Bool = false {
        didSet {
            if !isDragging && oldValue {
                if autoscroll > 0 {
                    state.tempOnePageValue = scrollOffset - scrollOffset.rounded(.towardZero)
                } else if autoscroll < 0 {
                    state.tempOnePageValue = scrollOffset.rounded(.towardZero) - scrollOffset
                }
            }
        }
    }
    var isDecelerating: Bool = false
    var isScrolling: Bool = false

    let contentView: UIView
    override init(frame: CGRect) {
        contentView = UIView(frame: CGRect(origin: .zero, size: frame.size))
        super.init(frame: frame)
        configInit()
    }
    required init?(coder: NSCoder) {
        contentView = UIView()
        super.init(coder: coder)
        configInit()
        contentView.frame = bounds
        if superview != nil {
            startAnimation()
        }
    }
    func configInit() {
        addSubview(contentView)
        setupGesture()
        accessibilityTraits = .allowsDirectInteraction
        isAccessibilityElement = true
        if dataSource != nil {
            reloadData()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        layOutItemViews()
    }
    
    public override func didMoveToSuperview() {
        if superview != nil {
            startAnimation()
        } else {
            stopAnimation()
        }
    }
    deinit {
        stopAnimation()
    }
}
extension iCarousel {
    func changeScrollOffset(_ newValue: CGFloat) {
        resetScrollingState()
        updateOffsetValues(to: newValue)
        if hasOffsetChanged(from: _scrollOffset, to: newValue) {
            applyScrollOffset(newValue)
        }
    }

    private func resetScrollingState() {
        isScrolling = false
        isDecelerating = false
    }

    private func updateOffsetValues(to newValue: CGFloat) {
        state.startOffset = newValue
        state.endOffset = newValue
    }

    private func hasOffsetChanged(from oldValue: CGFloat, to newValue: CGFloat) -> Bool {
        abs(newValue - oldValue) > CGFloat.ulpOfOne
    }

    private func applyScrollOffset(_ newValue: CGFloat) {
        _scrollOffset = newValue
        depthSortViews()
        didScroll()
    }
}
