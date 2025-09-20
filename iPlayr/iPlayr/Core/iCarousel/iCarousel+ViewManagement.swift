import UIKit

extension iCarousel {

    var currentItemView: UIView? {
        itemView(at: currentItemIndex)
    }

    func itemView(at index: Int) -> UIView? {
        itemViews[index]
    }

    func index(of itemView: UIView) -> Int? {
        itemViews.first { $0.value === itemView }?.key
    }

    func itemView(at point: CGPoint) -> UIView? {
        let sortedCells = getSortedCellsByDepth()
        let hitCell = findHitCell(in: sortedCells, at: point)
        return hitCell?.child
    }

    private func getSortedCellsByDepth() -> [ItemCell] {
        itemViews.values
            .compactMap { $0.itemCell }
            .sorted(by: compareViewDepth)
    }

    private func findHitCell(in cells: [ItemCell], at point: CGPoint) -> ItemCell? {
        cells.last { cell in
            cell.layer.hitTest(point) != nil
        }
    }
}

extension iCarousel {
    func setItemView(_ itemView: UIView, forIndex index: Int) {
        itemViews[index] = itemView
    }
}
