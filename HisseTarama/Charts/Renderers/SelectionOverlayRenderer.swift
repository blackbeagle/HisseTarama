import Cocoa

final class SelectionOverlayRenderer {

    // MARK: - Properties

    weak var view: NSView?

    var coordinateSystem: ChartCoordinateSystem!

    var theme: ChartTheme = .default

    /// Grafikte seçili olan görünür mum index'i
    var highlightedIndex: Int?

    /// Mouse'un grafik üzerindeki konumu
    var crosshairPoint: CGPoint?

    /// period -> SMA değerleri
    var activeSMAs: [Int: [Double?]] = [:]

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

        guard
            let mousePoint = crosshairPoint,
            chartRect.contains(mousePoint)
        else {
            return
        }

        // -------------------------------------------------
        // Mouse Y koordinatını fiyat değerine çevir
        // -------------------------------------------------

        let mouseY =
            min(
                max(
                    mousePoint.y,
                    chartRect.minY
                ),
                chartRect.maxY
            )

        let priceRatio =
            Double(
                mouseY - chartRect.minY
            ) /
            Double(
                chartRect.height
            )

        let mousePrice =
            coordinateSystem.minPrice +
            (
                coordinateSystem.maxPrice -
                coordinateSystem.minPrice
            ) * priceRatio

        // -------------------------------------------------
        // Crosshair
        // -------------------------------------------------

        let dash: [CGFloat] = [4, 4]

        // Dikey çizgi
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

        theme.crosshairColor.setStroke()

        vertical.stroke()

        // Yatay çizgi
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

        theme.crosshairColor.setStroke()

        horizontal.stroke()

        // -------------------------------------------------
        // Labels
        // -------------------------------------------------

        if theme.showPriceLabel {

            drawPriceLabel(
                price: mousePrice,
                y: mouseY
            )
        }

        drawDateLabel(
            date: candle.date,
            x: x
        )

        // -------------------------------------------------
        // Information Panel
        // -------------------------------------------------

        if theme.showTooltip {

            drawInformationPanel(
                candle: candle,
                visibleIndex: index,
                view: view
            )
        }
    }

    // MARK: - Price Label

    private func drawPriceLabel(
        price: Double,
        y: CGFloat
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
                    theme.priceLabelText
            ]

        let size =
            text.size(
                withAttributes: attributes
            )

        let rect = CGRect(

            x:
                coordinateSystem.chartRect.maxX +
                6,

            y:
                y -
                size.height / 2 -
                2,

            width:
                size.width +
                8,

            height:
                size.height +
                4
        )

        let background =
            NSBezierPath(
                roundedRect: rect,
                xRadius: 4,
                yRadius: 4
            )

        theme.priceLabelBackground.setFill()

        background.fill()

        text.draw(
            at: CGPoint(
                x: rect.minX + 4,
                y: rect.minY + 2
            ),
            withAttributes: attributes
        )
    }

    // MARK: - Date Label

    private func drawDateLabel(
        date: Date,
        x: CGFloat
    ) {

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(
                identifier: "tr_TR"
            )

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

            x:
                x -
                size.width / 2 -
                4,

            y:
                4,

            width:
                size.width +
                8,

            height:
                size.height +
                4
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

    // MARK: - Information Panel

    private func drawInformationPanel(
        candle: Candlestick,
        visibleIndex: Int,
        view: NSView
    ) {

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(
                identifier: "tr_TR"
            )

        formatter.dateFormat =
            "dd MMM yyyy"

        let dateText =
            formatter.string(
                from: candle.date
            )

        var lines: [String] = [

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

        // -------------------------------------------------
        // KRİTİK NOKTA
        //
        // visibleIndex sadece ekrandaki index'tir.
        //
        // SMA dizileri ise tüm veri setine göre tutuluyor.
        // Bu nedenle gerçek/global index'i kullanmalıyız.
        // -------------------------------------------------

        let globalIndex =
            coordinateSystem.globalIndex(
                fromVisibleIndex: visibleIndex
            )

        let sortedSMAs =
            activeSMAs.keys.sorted()

        for period in sortedSMAs {

            guard
                let smaValues =
                    activeSMAs[period]
            else {
                continue
            }

            guard
                globalIndex >= 0,
                globalIndex < smaValues.count
            else {
                continue
            }

            guard
                let value =
                    smaValues[globalIndex]
            else {
                continue
            }

            lines.append(
                String(
                    format: "SMA%-3d %.2f",
                    period,
                    value
                )
            )
        }

        // -------------------------------------------------
        // Attributes
        // -------------------------------------------------

        let titleAttributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    NSFont.boldSystemFont(
                        ofSize: 12
                    ),

                .foregroundColor:
                    NSColor.labelColor
            ]

        let panelWidth: CGFloat = 145

        let lineHeight: CGFloat = 18

        let panelHeight =
            12 +
            CGFloat(lines.count) *
            lineHeight

        let panelRect = CGRect(

            x:
                12,

            y:
                view.bounds.height -
                panelHeight -
                42,

            width:
                panelWidth,

            height:
                panelHeight
        )

        // -------------------------------------------------
        // Background
        // -------------------------------------------------

        let background =
            NSBezierPath(
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

        // -------------------------------------------------
        // Date
        // -------------------------------------------------

        if let first = lines.first {

            (first as NSString).draw(

                at: CGPoint(

                    x:
                        panelRect.minX +
                        8,

                    y:
                        panelRect.maxY -
                        lineHeight -
                        2
                ),

                withAttributes:
                    titleAttributes
            )
        }

        // -------------------------------------------------
        // Values
        // -------------------------------------------------

        if lines.count > 1 {

            for index in 1..<lines.count {

                let line =
                    lines[index]

                // -----------------------------------------
                // SMA satırının period'unu bul
                // -----------------------------------------

                let foregroundColor =
                    colorForInformationLine(
                        line: line
                    )

                let valueAttributes:
                    [NSAttributedString.Key: Any] = [

                        .font:
                            NSFont.monospacedDigitSystemFont(
                                ofSize: 11,
                                weight: .regular
                            ),

                        .foregroundColor:
                            foregroundColor
                    ]

                (line as NSString).draw(

                    at: CGPoint(

                        x:
                            panelRect.minX +
                            8,

                        y:
                            panelRect.maxY -
                            CGFloat(index + 1) *
                            lineHeight
                    ),

                    withAttributes:
                        valueAttributes
                )
            }
        }
    }

    // MARK: - SMA Information Color

    private func colorForInformationLine(
        line: String
    ) -> NSColor {

        guard line.hasPrefix("SMA") else {
            return NSColor.secondaryLabelColor
        }

        let components =
            line.split(
                whereSeparator: { $0.isWhitespace }
            )

        guard
            let firstComponent = components.first
        else {
            return NSColor.secondaryLabelColor
        }

        let periodText =
            String(firstComponent.dropFirst(3))

        guard
            let period = Int(periodText)
        else {
            return NSColor.secondaryLabelColor
        }

        return theme.smaColors[period]
            ?? NSColor.secondaryLabelColor
    }
    
}
