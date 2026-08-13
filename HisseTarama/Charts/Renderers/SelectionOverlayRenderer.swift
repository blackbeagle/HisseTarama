import Cocoa

final class SelectionOverlayRenderer {


weak var view: NSView?

var coordinateSystem: ChartCoordinateSystem!

var theme: ChartTheme = .default

var highlightedIndex: Int?

var crosshairPoint: CGPoint?

var activeSMAs: [Int: [Double?]] = [:]

func draw() {

    guard
        let view = view,
        let coordinateSystem = coordinateSystem,
        let index = highlightedIndex,
        let candle = coordinateSystem.candle(
            atVisibleIndex: index
        )
    else {
        return
    }

    let chartRect = coordinateSystem.chartRect

    let x = coordinateSystem.x(
        forVisibleIndex: index
    )

    guard
        let mousePoint = crosshairPoint,
        chartRect.contains(mousePoint)
    else {
        return
    }

    let mouseY = min(
        max(
            mousePoint.y,
            chartRect.minY
        ),
        chartRect.maxY
    )

    let priceRatio =
        Double(mouseY - chartRect.minY) /
        Double(chartRect.height)

    let mousePrice =
        coordinateSystem.minPrice +
        (
            coordinateSystem.maxPrice -
            coordinateSystem.minPrice
        ) * priceRatio

    let dash: [CGFloat] = [4, 4]

    let vertical = NSBezierPath()

    vertical.move(
        to: NSPoint(
            x: x,
            y: chartRect.minY
        )
    )

    vertical.line(
        to: NSPoint(
            x: x,
            y: chartRect.maxY
        )
    )

    vertical.lineWidth = 0.8

    vertical.setLineDash(
        dash,
        count: dash.count,
        phase: 0
    )

    NSColor.systemGray
        .withAlphaComponent(0.55)
        .setStroke()

    vertical.stroke()

    let horizontal = NSBezierPath()

    horizontal.move(
        to: NSPoint(
            x: chartRect.minX,
            y: mouseY
        )
    )

    horizontal.line(
        to: NSPoint(
            x: chartRect.maxX,
            y: mouseY
        )
    )

    horizontal.lineWidth = 0.8

    horizontal.setLineDash(
        dash,
        count: dash.count,
        phase: 0
    )

    NSColor.systemGray
        .withAlphaComponent(0.55)
        .setStroke()

    horizontal.stroke()

    drawPriceLabel(
        price: mousePrice,
        y: mouseY
    )

    drawDateLabel(
        date: candle.date,
        x: x
    )

    drawInformationPanel(
        candle: candle,
        visibleIndex: index,
        view: view
    )
}

private func drawPriceLabel(
    price: Double,
    y: CGFloat
) {

    let text = String(
        format: "%.2f",
        price
    ) as NSString

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11),
        .foregroundColor: NSColor.white
    ]

    let size = text.size(
        withAttributes: attributes
    )

    let rect = CGRect(
        x: coordinateSystem.chartRect.maxX + 6,
        y: y - size.height / 2 - 2,
        width: size.width + 8,
        height: size.height + 4
    )

    let background = NSBezierPath(
        roundedRect: rect,
        xRadius: 4,
        yRadius: 4
    )

    NSColor.systemBlue.setFill()

    background.fill()

    text.draw(
        at: CGPoint(
            x: rect.minX + 4,
            y: rect.minY + 2
        ),
        withAttributes: attributes
    )
}

private func drawDateLabel(
    date: Date,
    x: CGFloat
) {

    let formatter = DateFormatter()

    formatter.locale = Locale(
        identifier: "tr_TR"
    )

    formatter.dateFormat = "dd MMM yyyy"

    let text = formatter.string(
        from: date
    ) as NSString

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11),
        .foregroundColor: NSColor.white
    ]

    let size = text.size(
        withAttributes: attributes
    )

    let rect = CGRect(
        x: x - size.width / 2 - 4,
        y: 4,
        width: size.width + 8,
        height: size.height + 4
    )

    let background = NSBezierPath(
        roundedRect: rect,
        xRadius: 4,
        yRadius: 4
    )

    NSColor.systemBlue.setFill()

    background.fill()

    text.draw(
        at: CGPoint(
            x: rect.minX + 4,
            y: rect.minY + 2
        ),
        withAttributes: attributes
    )
}

private func drawInformationPanel(
    candle: Candlestick,
    visibleIndex: Int,
    view: NSView
) {

    let formatter = DateFormatter()

    formatter.locale = Locale(
        identifier: "tr_TR"
    )

    formatter.dateFormat = "dd MMM yyyy"

    let dateText = formatter.string(
        from: candle.date
    )

    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: 12),
        .foregroundColor: NSColor.labelColor
    ]

    let valueAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(
            ofSize: 11,
            weight: .regular
        ),
        .foregroundColor: NSColor.secondaryLabelColor
    ]

    let lines: [String] = [
        dateText,
        String(
            format: "Max     %.2f",
            candle.max
        ),
        String(
            format: "Min     %.2f",
            candle.min
        ),
        String(
            format: "AOF     %.2f",
            candle.weightedAverage
        )
    ]

    let sortedSMAs =
        activeSMAs.keys.sorted()

    let panelWidth: CGFloat = 145
    let lineHeight: CGFloat = 18

    let totalLineCount =
        lines.count +
        sortedSMAs.reduce(0) { count, period in

            guard
                let values = activeSMAs[period],
                let viewport = coordinateSystem.viewport
            else {
                return count
            }

            let globalIndex =
                viewport.firstVisibleBar +
                visibleIndex

            guard
                globalIndex >= 0,
                globalIndex < values.count,
                values[globalIndex] != nil
            else {
                return count
            }

            return count + 1
        }

    let panelHeight =
        12 +
        CGFloat(totalLineCount) *
        lineHeight

    let panelRect = CGRect(
        x: 12,
        y: view.bounds.height - panelHeight - 42,
        width: panelWidth,
        height: panelHeight
    )

    let background = NSBezierPath(
        roundedRect: panelRect,
        xRadius: 6,
        yRadius: 6
    )

    NSColor.windowBackgroundColor
        .withAlphaComponent(0.92)
        .setFill()

    background.fill()

    NSColor.separatorColor
        .withAlphaComponent(0.5)
        .setStroke()

    background.lineWidth = 0.5

    background.stroke()

    var currentLine = 0

    (dateText as NSString).draw(
        at: CGPoint(
            x: panelRect.minX + 8,
            y:
                panelRect.maxY -
                CGFloat(currentLine + 1) *
                lineHeight -
                2
        ),
        withAttributes: titleAttributes
    )

    currentLine += 1

    let baseLines = [
        String(
            format: "Max     %.2f",
            candle.max
        ),
        String(
            format: "Min     %.2f",
            candle.min
        ),
        String(
            format: "AOF     %.2f",
            candle.weightedAverage
        )
    ]

    for line in baseLines {

        (line as NSString).draw(
            at: CGPoint(
                x: panelRect.minX + 8,
                y:
                    panelRect.maxY -
                    CGFloat(currentLine + 1) *
                    lineHeight
            ),
            withAttributes: valueAttributes
        )

        currentLine += 1
    }

    for period in sortedSMAs {

        guard
            let values = activeSMAs[period],
            let viewport = coordinateSystem.viewport
        else {
            continue
        }

        let globalIndex =
            viewport.firstVisibleBar +
            visibleIndex

        guard
            globalIndex >= 0,
            globalIndex < values.count,
            let value = values[globalIndex]
        else {
            continue
        }

        let smaColor =
            theme.smaColors[period]
            ?? NSColor.systemGray

        let smaAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(
                ofSize: 11,
                weight: .regular
            ),
            .foregroundColor: smaColor
        ]

        let line = String(
            format: "SMA%-3d %.2f",
            period,
            value
        ) as NSString

        line.draw(
            at: CGPoint(
                x: panelRect.minX + 8,
                y:
                    panelRect.maxY -
                    CGFloat(currentLine + 1) *
                    lineHeight
            ),
            withAttributes: smaAttributes
        )

        currentLine += 1
    }
}



}

