import CoreGraphics

/// Layout constants shared by the Cover Flow carousel (`CoverFlowView`) and
/// its individual covers (`AlbumCover`, `SongListView`). Kept in one place
/// because `coverSize` must match the collapsed size `AlbumCover` animates
/// from, and `expandedSize` must match the size it flips open to.
enum CoverFlowMetrics {
    /// Width/height of a cover in its face-down (album art) state.
    static let coverSize: CGFloat = 160
    /// Width/height of a cover once flipped open to show its song list.
    static let expandedSize: CGFloat = 300
    /// Horizontal distance, in points, the carousel scrolls per index step.
    static let itemStep: CGFloat = 180
    /// Strength of the 3D rotation applied to off-center covers (0...1).
    static let tilt: CGFloat = 0.7
    /// Extra per-index horizontal spacing layered on top of the tilt-driven offset.
    static let spacing: CGFloat = 0.2
    /// Number of covers rendered on each side of the selected index.
    static let windowRadius = 5
}
