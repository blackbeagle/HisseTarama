import Cocoa

final class ChartCoordinateSystem {

    // MARK: - Public Properties

    var chartRect: CGRect = .zero

    var candles: [Candlestick] = []

    var viewport: ChartViewport?

    var topPadding: Double = 0.05
    
    // MARK: - Cached Values

    private(set) var cachedVisibleCandles: [Candlestick] = []

    private(set) var cachedMinPrice: Double = 0

    private(set) var cachedMaxPrice: Double = 0

    private(set) var cachedPriceRange: Double = 1

    private(set) var cachedXScale: CGFloat = 1

    private(set) var cachedYScale: CGFloat = 1

    private(set) var cachedBodyWidth: CGFloat = 6
    
    var bodyWidth: CGFloat {

        cachedBodyWidth
    }

    // MARK: - Visible Data
    var visibleCandles: [Candlestick] {
        cachedVisibleCandles
    }
    
    // MARK: - Price Range

    var minPrice: Double {
        cachedMinPrice
    }

    var maxPrice: Double {
        cachedMaxPrice
    }

    // MARK: - Scale

    var xScale: CGFloat {
        cachedXScale
    }

    var yScale: CGFloat {
        cachedYScale
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

        // ---------------------------------------------
        // 1. Cache sıfırlama
        // ---------------------------------------------

        cachedVisibleCandles = []
        cachedMinPrice = 0
        cachedMaxPrice = 0
        cachedPriceRange = 1
        cachedXScale = 1
        cachedYScale = 1
        cachedBodyWidth = 6

        // ---------------------------------------------
        // 2. Viewport kontrolü
        // ---------------------------------------------

        guard
            let viewport = viewport,
            !candles.isEmpty,
            chartRect.width > 0,
            chartRect.height > 0
        else {
            return
        }

        // ---------------------------------------------
        // 3. Visible Range
        // ---------------------------------------------

        let range = viewport.visibleRange()

        guard !range.isEmpty else {
            return
        }

        guard
            range.lowerBound >= 0,
            range.upperBound <= candles.count
        else {
            return
        }

        // ---------------------------------------------
        // 4. Visible Candles
        // ---------------------------------------------

        cachedVisibleCandles = Array(candles[range])

        guard !cachedVisibleCandles.isEmpty else {
            return
        }

        // ---------------------------------------------
        // 5. Raw Price Range
        // ---------------------------------------------

        let rawMinPrice =
            cachedVisibleCandles
                .map(\.min)
                .min() ?? 0

        let rawMaxPrice =
            cachedVisibleCandles
                .map(\.max)
                .max() ?? 0

        // ---------------------------------------------
        // 6. Price Padding
        // ---------------------------------------------

        let rawRange =
            max(
                rawMaxPrice - rawMinPrice,
                0.000001
            )

        cachedMinPrice =
            rawMinPrice -
            rawRange * topPadding

        cachedMaxPrice =
            rawMaxPrice +
            rawRange * topPadding

        cachedPriceRange =
            max(
                cachedMaxPrice - cachedMinPrice,
                0.000001
            )

        // ---------------------------------------------
        // 7. X Scale
        // ---------------------------------------------

        if cachedVisibleCandles.count > 1 {

            cachedXScale =
                chartRect.width /
                CGFloat(cachedVisibleCandles.count - 1)

        } else {

            cachedXScale =
                chartRect.width
        }

        // ---------------------------------------------
        // 8. Y Scale
        // ---------------------------------------------

        cachedYScale =
            chartRect.height /
            CGFloat(cachedPriceRange)

        // ---------------------------------------------
        // 9. Candle Body Width
        // ---------------------------------------------

        cachedBodyWidth =
            min(
                10,
                cachedXScale * 0.55
            )
    }
    
    
}
