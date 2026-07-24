import Cocoa

final class ChartCoordinateSystem {

    // MARK: - Public Properties

    var chartRect: CGRect = .zero

    var candles: [Candlestick] = []

    var viewport: ChartViewport?

    var topPadding: Double = 0.05
    
    var bodyWidth: CGFloat {

        max(2, min(10, xScale * 0.55))
    }

    // MARK: - Visible Data

    var visibleCandles: [Candlestick] {

        guard
            let viewport = viewport,
            !candles.isEmpty
        else {
            return []
        }

        let range = viewport.visibleRange()

        guard
            range.lowerBound < candles.count,
            range.upperBound <= candles.count
        else {
            return []
        }

        return Array(candles[range])
    }

    // MARK: - Price Range

    var minPrice: Double {

        let value = visibleCandles.map(\.min).min() ?? 0
        let range = maxPriceRaw - value

        return value - range * topPadding
    }

    var maxPrice: Double {

        let value = visibleCandles.map(\.max).max() ?? 0
        let range = value - minPriceRaw

        return value + range * topPadding
    }

    private var minPriceRaw: Double {
        visibleCandles.map(\.min).min() ?? 0
    }

    private var maxPriceRaw: Double {
        visibleCandles.map(\.max).max() ?? 0
    }

    // MARK: - Scale

    var xScale: CGFloat {

        guard visibleCandles.count > 1 else {

            return chartRect.width
        }

        return chartRect.width /
        CGFloat(visibleCandles.count - 1)
    }

    var yScale: CGFloat {

        let range = maxPrice - minPrice

        guard range > 0 else {

            return 1
        }

        return chartRect.height / CGFloat(range)
    }

    // MARK: - Coordinate Conversion

    func x(forVisibleIndex index: Int) -> CGFloat {

        chartRect.minX +
        CGFloat(index) * xScale
    }

    func y(forPrice price: Double) -> CGFloat {

        CGFloat(price - minPrice) *
        yScale +
        chartRect.minY
    }

    func visibleIndex(atX x: CGFloat) -> Int? {

        guard !visibleCandles.isEmpty else {

            return nil
        }

        let value = Int(
            round(
                (x - chartRect.minX) / xScale
            )
        )

        guard xScale > 0 else {
            return nil
        }
        
        guard value >= 0,
              value < visibleCandles.count
        else {
            return nil
        }

        return value
    }

    func globalIndex(fromVisibleIndex index: Int) -> Int {

        guard let viewport = viewport else {
            return index
        }

        return viewport.firstVisibleBar + index
    }
    func visibleIndex(fromGlobalIndex index: Int) -> Int? {

        guard let viewport = viewport else {
                return nil
            }

        guard
            index >= viewport.firstVisibleBar,
            index <= viewport.lastVisibleBar
        else {

            return nil
        }

        return index - viewport.firstVisibleBar
    }

    func candle(atVisibleIndex index: Int) -> Candlestick? {

        guard
            index >= 0,
            index < visibleCandles.count
        else {

            return nil
        }

        return visibleCandles[index]
    }

    func candle(atGlobalIndex index: Int) -> Candlestick? {

        guard
            index >= 0,
            index < candles.count
        else {

            return nil
        }

        return candles[index]
    }
    
    // MARK: - Prepare

    func prepare() {

        // Şimdilik boş.
        // İleride visible candles, min/max,
        // xScale ve yScale burada cache'lenecek.
    }
    
    
}
