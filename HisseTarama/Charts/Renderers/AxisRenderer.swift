import Cocoa

final class AxisRenderer {

    weak var view: NSView?

    var coordinateSystem: ChartCoordinateSystem!

    var theme: ChartTheme = .default

    func draw() {

        guard let view else { return }

        let chartRect = coordinateSystem.chartRect
        let candles = coordinateSystem.visibleCandles

        guard !candles.isEmpty else { return }

        //----------------------------------------------------
        // Y AXIS
        //----------------------------------------------------

        let labelAttributes: [NSAttributedString.Key: Any] = [

            .font: NSFont.systemFont(ofSize: 11),

            .foregroundColor: theme.axisLabelColor

        ]

        let labelCount = 5

        for i in 0...labelCount {

            let ratio = Double(i) / Double(labelCount)

            let price =
            coordinateSystem.minPrice +
            (coordinateSystem.maxPrice - coordinateSystem.minPrice) * ratio

            let y =
            chartRect.minY +
            CGFloat(ratio) * chartRect.height

            let text =
            NSString(format: "%.2f", price)

            let size =
            text.size(withAttributes: labelAttributes)

            text.draw(
                at: NSPoint(
                    x: 8,
                    y: y - size.height / 2
                ),
                withAttributes: labelAttributes
            )
        }

        //----------------------------------------------------
        // X AXIS
        //----------------------------------------------------

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMM"

        let first = candles.first!
        let last = candles.last!

        drawDate(
            formatter.string(from: first.date),
            x: chartRect.minX,
            chartRect: chartRect,
            attributes: labelAttributes
        )

        drawDate(
            formatter.string(from: last.date),
            x: chartRect.maxX,
            chartRect: chartRect,
            attributes: labelAttributes,
            alignRight: true
        )

        let middle = candles.count / 2

        if middle > 0 {

            drawDate(
                formatter.string(from: candles[middle].date),
                x: coordinateSystem.x(forVisibleIndex: middle),
                chartRect: chartRect,
                attributes: labelAttributes,
                centered: true
            )
        }

        //----------------------------------------------------
        // Axis Titles
        //----------------------------------------------------

        let titleAttributes: [NSAttributedString.Key: Any] = [

            .font: NSFont.systemFont(ofSize: 10),

            .foregroundColor: theme.axisTitleColor

        ]

        ("Fiyat (₺)" as NSString).draw(
            at: NSPoint(
                x: 8,
                y: view.bounds.height - 18
            ),
            withAttributes: titleAttributes
        )

        let time = "Zaman" as NSString

        let size = time.size(withAttributes: titleAttributes)

        time.draw(
            at: NSPoint(
                x: view.bounds.width - size.width - 10,
                y: 8
            ),
            withAttributes: titleAttributes
        )
    }

    // MARK: -

    private func drawDate(
        _ text: String,
        x: CGFloat,
        chartRect: CGRect,
        attributes: [NSAttributedString.Key:Any],
        alignRight: Bool = false,
        centered: Bool = false
    ) {

        let string = text as NSString

        let size =
        string.size(withAttributes: attributes)

        var drawX = x

        if alignRight {

            drawX -= size.width

        }

        if centered {

            drawX -= size.width / 2

        }

        string.draw(
            at: NSPoint(
                x: drawX,
                y: chartRect.maxY + 8
            ),
            withAttributes: attributes
        )
    }
}
