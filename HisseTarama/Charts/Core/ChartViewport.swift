import Foundation

final class ChartViewport {

    // MARK: - Public Properties

    /// Aynı anda ekranda gösterilecek bar sayısı
    var visibleBarCount: Int = 150 {
        didSet {
            visibleBarCount = max(20, visibleBarCount)
            clamp()
        }
    }
    
    

    /// Toplam bar sayısı
    private(set) var totalBarCount: Int = 0

    /// İlk görünen bar
    private(set) var firstVisibleBar: Int = 0

    /// Son görünen bar
    var lastVisibleBar: Int {
        min(totalBarCount - 1,
            firstVisibleBar + visibleBarCount - 1)
    }

    var hasData: Bool {
        totalBarCount > 0
    }

    
    var isAtLastBar: Bool {

        lastVisibleBar >= totalBarCount - 1
    }
    // MARK: - Data

    func update(totalBars: Int) {

        totalBarCount = max(0, totalBars)

        if totalBarCount <= visibleBarCount {
            firstVisibleBar = 0
        } else {
            firstVisibleBar = max(
                0,
                totalBarCount - visibleBarCount
            )
        }
    }

    // MARK: - Navigation

    func scrollLeft(by bars: Int = 20) {

        firstVisibleBar = max(
            0,
            firstVisibleBar - bars
        )
    }

    func scrollRight(by bars: Int = 20) {

        firstVisibleBar = min(
            max(0, totalBarCount - visibleBarCount),
            firstVisibleBar + bars
        )
    }

    func scroll(by bars: Int) {

        if bars < 0 {
            scrollLeft(by: abs(bars))
        } else {
            scrollRight(by: bars)
        }
    }

    func moveToLast() {

        firstVisibleBar = max(
            0,
            totalBarCount - visibleBarCount
        )
    }

    func moveToFirst() {

        firstVisibleBar = 0
    }

    func center(on index: Int) {

        guard totalBarCount > 0 else { return }

        firstVisibleBar = index - visibleBarCount / 2

        clamp()
    }

    // MARK: - Visible Range

    func visibleRange() -> Range<Int> {

        guard totalBarCount > 0 else {

            return 0..<0
        }

        let end = min(
            totalBarCount,
            firstVisibleBar + visibleBarCount
        )

        return firstVisibleBar..<end
    }

    // MARK: - Helpers

    func clamp() {

        firstVisibleBar =
            max(
                0,
                min(
                    firstVisibleBar,
                    max(
                        0,
                        totalBars - visibleBarCount
                    )
                )
            )
    }
}
