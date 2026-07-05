import Cocoa

final class CandleRenderer {

    var coordinateSystem: ChartCoordinateSystem!
    var theme: ChartTheme = .default

    func draw() {

        let candles = coordinateSystem.visibleCandles

        guard !candles.isEmpty else { return }

        let bodyWidth = coordinateSystem.bodyWidth

        for (index, stick) in candles.enumerated() {

            drawSingleCandle(
                candle: stick,
                visibleIndex: index,
                bodyWidth: bodyWidth
            )
        }
    }

    // MARK: -

    private func drawSingleCandle(
        candle: Candlestick,
        visibleIndex: Int,
        bodyWidth: CGFloat
    ) {

        let x = coordinateSystem.x(forVisibleIndex: visibleIndex)

        let yLow = coordinateSystem.y(forPrice: candle.min)

        let yHigh = coordinateSystem.y(forPrice: candle.max)

        let yAverage = coordinateSystem.y(forPrice: candle.weightedAverage)

        let previousAverage: Double

        if visibleIndex > 0 {

            previousAverage =
                coordinateSystem.visibleCandles[
                    visibleIndex - 1
                ].weightedAverage

        } else {

            let global =
                coordinateSystem.globalIndex(
                    fromVisibleIndex: visibleIndex
                )

            if global > 0 {

                previousAverage =
                    coordinateSystem.candles[
                        global - 1
                    ].weightedAverage

            } else {

                previousAverage =
                    candle.weightedAverage
            }
        }

        let rising =
            candle.weightedAverage >= previousAverage

        //---------------------------------------
        // Wick
        //---------------------------------------

        let wick = NSBezierPath()

        wick.move(to: NSPoint(x: x, y: yLow))

        wick.line(to: NSPoint(x: x, y: yHigh))

        wick.lineWidth = 1

        (rising
            ? NSColor.systemGreen
            : NSColor.systemRed)
            .setStroke()

        wick.stroke()

        //---------------------------------------
        // Ortalama çizgisi
        //---------------------------------------

        let avg = NSBezierPath()

        avg.move(
            to: NSPoint(
                x: x - bodyWidth / 2,
                y: yAverage
            )
        )

        avg.line(
            to: NSPoint(
                x: x + bodyWidth / 2,
                y: yAverage
            )
        )

        avg.lineWidth = 1.3

        (rising
            ? NSColor.systemGreen.withAlphaComponent(0.95)
            : NSColor.systemRed.withAlphaComponent(0.95))
            .setStroke()

        avg.stroke()
    }
}
