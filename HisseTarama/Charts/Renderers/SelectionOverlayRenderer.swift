import Cocoa

final class SelectionOverlayRenderer {


// MARK: - Properties

weak var view: NSView?

var coordinateSystem: ChartCoordinateSystem!

var theme: ChartTheme = .default

var highlightedIndex: Int?

// MARK: - Draw

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

    let chartRect =
        coordinateSystem.chartRect

    let x =
        coordinateSystem.x(
            forVisibleIndex: index
        )

    let y =
        coordinateSystem.y(
            forPrice: candle.weightedAverage
        )

    //--------------------------------------------------
    // Vertical Crosshair
    //--------------------------------------------------

    let vertical =
        NSBezierPath()

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

    let dash: [CGFloat] = [4, 4]

    vertical.setLineDash(
        dash,
        count: dash.count,
        phase: 0
    )

    NSColor.systemGray
        .withAlphaComponent(0.55)
        .setStroke()

    vertical.stroke()

    //--------------------------------------------------
    // Horizontal Crosshair
    //--------------------------------------------------

    let horizontal =
        NSBezierPath()

    horizontal.move(
        to: NSPoint(
            x: chartRect.minX,
            y: y
        )
    )

    horizontal.line(
        to: NSPoint(
            x: chartRect.maxX,
            y: y
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

    //--------------------------------------------------
    // Labels
    //--------------------------------------------------

    drawPriceLabel(
        price: candle.weightedAverage,
        y: y,
        view: view
    )

    drawDateLabel(
        date: candle.date,
        x: x,
        view: view
    )
}


}

// MARK: - Price Label

private extension SelectionOverlayRenderer {

func drawPriceLabel(
    price: Double,
    y: CGFloat,
    view: NSView
) {

    let text =
        String(
            format: "%.2f",
            price
        ) as NSString

    let attributes:
        [NSAttributedString.Key: Any] = [

            .font:
                NSFont.systemFont(
                    ofSize: 11
                ),

            .foregroundColor:
                NSColor.white
        ]

    let size =
        text.size(
            withAttributes: attributes
        )

    let rect = CGRect(
        x: coordinateSystem.chartRect.maxX + 6,
        y: y - size.height / 2 - 2,
        width: size.width + 8,
        height: size.height + 4
    )

    let background =
        NSBezierPath(
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


}

// MARK: - Date Label

private extension SelectionOverlayRenderer {


func drawDateLabel(
    date: Date,
    x: CGFloat,
    view: NSView
) {

    let formatter =
        DateFormatter()

    formatter.locale =
        Locale(identifier: "tr_TR")

    formatter.dateFormat =
        "dd MMM yyyy"

    let text =
        formatter.string(
            from: date
        ) as NSString

    let attributes:
        [NSAttributedString.Key: Any] = [

            .font:
                NSFont.systemFont(
                    ofSize: 11
                ),

            .foregroundColor:
                NSColor.white
        ]

    let size =
        text.size(
            withAttributes: attributes
        )

    let rect = CGRect(
        x: x - size.width / 2 - 4,
        y: 4,
        width: size.width + 8,
        height: size.height + 4
    )

    let background =
        NSBezierPath(
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


}

