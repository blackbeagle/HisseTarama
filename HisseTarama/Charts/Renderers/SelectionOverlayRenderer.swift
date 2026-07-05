import Cocoa

final class SelectionOverlayRenderer {

    var coordinateSystem: ChartCoordinateSystem!

    var highlightedIndex: Int?

    func draw(in view: NSView) {

        guard
            let index = highlightedIndex,
            let candle = coordinateSystem.candle(atVisibleIndex: index)
        else {
            return
        }

        drawCrosshair(candle, index)

        drawHighlight(candle, index)

        drawPriceLabel(candle)

        drawDateLabel(candle, index)

        drawTooltip(candle)
    }
}
