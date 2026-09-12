import Cocoa

final class RevenueCostChartRenderer: NSView {

    struct DataPoint {
        let periodTitle: String
        let revenue: Double
        let cost: Double
    }

    private var data: [DataPoint] = []
    private var hoveredIndex: Int?
    private var trackingArea: NSTrackingArea?
    private var isUSDMode = false

    private let revenueFillColor =
        NSColor.systemGreen.withAlphaComponent(0.12)

    private let grossProfitFillColor =
        NSColor.systemGreen.withAlphaComponent(0.38)

    private let negativeGrossProfitFillColor =
        NSColor.systemGreen.withAlphaComponent(0.12)

    private let normalStrokeColor =
        NSColor.systemGreen.withAlphaComponent(0.55)

    private let borderColor =
        NSColor.separatorColor.withAlphaComponent(0.90)

    private let labelColor =
        NSColor.labelColor

    private let secondaryLabelColor =
        NSColor.secondaryLabelColor

    // MARK: - Data

    func setData(_ data: [DataPoint]) {

        // Her zaman eski dönem solda,
        // yeni dönem sağda olacak.
        self.data = data.sorted {
            periodSortKey($0.periodTitle) <
            periodSortKey($1.periodTitle)
        }

        hoveredIndex = nil
        needsDisplay = true
        updateTrackingArea()
    }

    func clear() {
        data.removeAll()
        hoveredIndex = nil
        needsDisplay = true
    }

    func setCurrency(isUSD: Bool) {
        isUSDMode = isUSD
        needsDisplay = true
    }

    // MARK: - Period Sorting

    private func periodSortKey(
        _ periodTitle: String
    ) -> (Int, Int) {

        let numbers =
            periodTitle
                .split(
                    whereSeparator: {
                        !$0.isNumber
                    }
                )
                .compactMap {
                    Int($0)
                }

        guard numbers.count >= 2 else {
            return (Int.max, Int.max)
        }

        let year = numbers[0]
        let period = numbers[1]

        let quarter: Int

        switch period {
        case 1:
            quarter = 1
        case 2:
            quarter = 2
        case 3:
            quarter = 3
        case 4:
            quarter = 4
        case 6:
            quarter = 2
        case 9:
            quarter = 3
        case 12:
            quarter = 4
        default:
            quarter = period
        }

        return (year, quarter)
    }

    // MARK: - Tracking

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [
                .mouseEnteredAndExited,
                .mouseMoved,
                .activeInKeyWindow,
                .inVisibleRect
            ],
            owner: self,
            userInfo: nil
        )

        trackingArea = area
        addTrackingArea(area)
    }

    private func updateTrackingArea() {

        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [
                .mouseEnteredAndExited,
                .mouseMoved,
                .activeInKeyWindow,
                .inVisibleRect
            ],
            owner: self,
            userInfo: nil
        )

        trackingArea = area
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        updateHover(with: event)
    }

    override func mouseMoved(with event: NSEvent) {
        updateHover(with: event)
    }

    override func mouseExited(with event: NSEvent) {

        if hoveredIndex != nil {
            hoveredIndex = nil
            needsDisplay = true
        }
    }

    private func updateHover(with event: NSEvent) {

        let location =
            convert(
                event.locationInWindow,
                from: nil
            )

        let index =
            barIndex(at: location)

        if hoveredIndex != index {
            hoveredIndex = index
            needsDisplay = true
        }
    }

    private func barIndex(
        at point: NSPoint
    ) -> Int? {

        guard !data.isEmpty else {
            return nil
        }

        let outerRect =
            bounds.insetBy(
                dx: 8,
                dy: 8
            )

        let plottingRect =
            CGRect(
                x: outerRect.minX + 60,
                y: outerRect.minY + 55,
                width: max(
                    0,
                    outerRect.width - 84
                ),
                height: max(
                    0,
                    outerRect.height - 113
                )
            )

        guard plottingRect.width > 0,
              plottingRect.height > 0 else {
            return nil
        }

        let slotWidth =
            plottingRect.width /
            CGFloat(data.count)

        let barWidth =
            min(
                slotWidth * 0.56,
                54
            )

        for index in data.indices {

            let centerX =
                plottingRect.minX +
                slotWidth * CGFloat(index) +
                slotWidth / 2

            let hitRect =
                CGRect(
                    x: centerX - barWidth / 2,
                    y: plottingRect.minY,
                    width: barWidth,
                    height: plottingRect.height
                )

            if hitRect.contains(point) {
                return index
            }
        }

        return nil
    }

    // MARK: - Draw

    override func draw(
        _ dirtyRect: NSRect
    ) {
        super.draw(dirtyRect)

        guard !data.isEmpty else {
            return
        }

        let outerRect =
            bounds.insetBy(
                dx: 8,
                dy: 8
            )

        drawChart(
            data: data,
            in: outerRect
        )
    }

    private func drawChart(
        data: [DataPoint],
        in outerRect: CGRect
    ) {

        let plottingRect =
            CGRect(
                x: outerRect.minX + 60,
                y: outerRect.minY + 55,
                width: max(
                    0,
                    outerRect.width - 84
                ),
                height: max(
                    0,
                    outerRect.height - 113
                )
            )

        guard plottingRect.width > 0,
              plottingRect.height > 0 else {
            return
        }

        drawOuterBorder(in: outerRect)
        drawLegend(in: outerRect)

        // Finansal verilerde hem hasılat hem maliyet
        // negatif işaretle gelebileceği için grafik
        // yüksekliği mutlak değer üzerinden hesaplanıyor.
        let values =
            data.flatMap { item -> [Double] in

                let revenue =
                    abs(item.revenue)

                let cost =
                    abs(item.cost)

                let grossProfit =
                    revenue - cost

                return [
                    0,
                    revenue,
                    grossProfit
                ]
            }

        let highestValue =
            values.max() ?? 0

        let lowestValue =
            min(
                values.min() ?? 0,
                0
            )

        var maximumValue =
            highestValue

        var minimumValue =
            lowestValue

        let rawRange =
            max(
                maximumValue - minimumValue,
                1
            )

        maximumValue +=
            rawRange * 0.08

        if minimumValue >= 0 {

            minimumValue = 0

        } else {

            minimumValue -=
                rawRange * 0.08
        }

        drawGrid(
            in: plottingRect,
            minimumValue: minimumValue,
            maximumValue: maximumValue
        )

        drawBars(
            in: plottingRect,
            minimumValue: minimumValue,
            maximumValue: maximumValue
        )

        drawPeriodLabels(
            in: plottingRect
        )
    }

    // MARK: - Border

    private func drawOuterBorder(
        in rect: CGRect
    ) {

        let path =
            NSBezierPath(
                roundedRect: rect,
                xRadius: 8,
                yRadius: 8
            )

        borderColor.setStroke()

        path.lineWidth = 1.4
        path.stroke()
    }

    // MARK: - Legend
    private func drawLegend(
        in rect: CGRect
    ) {
        let centerY =
            rect.maxY - 28

        let revenueText =
            "Hasılat"

        let costText =
            "Satışların Maliyeti"

        let font =
            NSFont.systemFont(
                ofSize: 10,
                weight: .medium
            )

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: secondaryLabelColor
        ]

        let revenueSize =
            (revenueText as NSString).size(
                withAttributes: attributes
            )

        let costSize =
            (costText as NSString).size(
                withAttributes: attributes
            )

        let markerSize: CGFloat = 8
        let spacing: CGFloat = 7
        let sectionSpacing: CGFloat = 22

        let totalWidth =
            markerSize +
            spacing +
            revenueSize.width +
            sectionSpacing +
            markerSize +
            spacing +
            costSize.width

        var x =
            rect.midX -
            totalWidth / 2

        // MARK: - Hasılat

        let revenueMarker =
            CGRect(
                x: x,
                y: centerY - markerSize / 2,
                width: markerSize,
                height: markerSize
            )

        // Hasılat = belirgin yeşil
        grossProfitFillColor.setFill()

        NSBezierPath(
            roundedRect: revenueMarker,
            xRadius: 2,
            yRadius: 2
        ).fill()

        x +=
            markerSize +
            spacing

        (revenueText as NSString).draw(
            at: NSPoint(
                x: x,
                y: centerY -
                    revenueSize.height / 2
            ),
            withAttributes: attributes
        )

        x +=
            revenueSize.width +
            sectionSpacing

        // MARK: - Satışların Maliyeti

        let costMarker =
            CGRect(
                x: x,
                y: centerY - markerSize / 2,
                width: markerSize,
                height: markerSize
            )

        // Satışların Maliyeti = soluk yeşil
        revenueFillColor.setFill()

        NSBezierPath(
            roundedRect: costMarker,
            xRadius: 2,
            yRadius: 2
        ).fill()

        x +=
            markerSize +
            spacing

        (costText as NSString).draw(
            at: NSPoint(
                x: x,
                y: centerY -
                    costSize.height / 2
            ),
            withAttributes: attributes
        )
    }

    // MARK: - Grid

    private func drawGrid(
        in rect: CGRect,
        minimumValue: Double,
        maximumValue: Double
    ) {

        let range =
            maximumValue -
            minimumValue

        guard range > 0 else {
            return
        }

        let gridCount = 4

        let zeroRatio =
            CGFloat(
                (0 - minimumValue) /
                range
            )

        let zeroY =
            rect.minY +
            rect.height *
            zeroRatio

        let zeroPath =
            NSBezierPath()

        zeroPath.move(
            to: NSPoint(
                x: rect.minX,
                y: zeroY
            )
        )

        zeroPath.line(
            to: NSPoint(
                x: rect.maxX,
                y: zeroY
            )
        )

        NSColor.white
            .withAlphaComponent(0.72)
            .setStroke()

        zeroPath.lineWidth = 1.2
        zeroPath.stroke()

        for index in 0...gridCount {

            let ratio =
                CGFloat(index) /
                CGFloat(gridCount)

            let value =
                minimumValue +
                range *
                Double(ratio)

            let y =
                rect.minY +
                rect.height *
                ratio

            if abs(value) <
                range * 0.001 {
                continue
            }

            let path =
                NSBezierPath()

            path.move(
                to: NSPoint(
                    x: rect.minX,
                    y: y
                )
            )

            path.line(
                to: NSPoint(
                    x: rect.maxX,
                    y: y
                )
            )

            NSColor.white
                .withAlphaComponent(0.16)
                .setStroke()

            path.lineWidth = 0.6
            path.stroke()

            let label =
                formattedValue(value)

            let attributes:
                [NSAttributedString.Key: Any] = [
                    .font:
                        NSFont.systemFont(
                            ofSize: 9
                        ),
                    .foregroundColor:
                        secondaryLabelColor
                ]

            let size =
                (label as NSString).size(
                    withAttributes: attributes
                )

            (label as NSString).draw(
                at: NSPoint(
                    x:
                        rect.minX -
                        10 -
                        size.width,
                    y:
                        y -
                        size.height / 2
                ),
                withAttributes: attributes
            )
        }
    }

    // MARK: - Bars

    private func drawBars(
        in rect: CGRect,
        minimumValue: Double,
        maximumValue: Double
    ) {

        guard !data.isEmpty else {
            return
        }

        let range =
            maximumValue -
            minimumValue

        guard range > 0 else {
            return
        }

        func yPosition(
            _ value: Double
        ) -> CGFloat {

            let ratio =
                CGFloat(
                    (value - minimumValue) /
                    range
                )

            return
                rect.minY +
                rect.height * ratio
        }

        let zeroY =
            yPosition(0)

        let slotWidth =
            rect.width /
            CGFloat(data.count)

        let barWidth =
            min(
                slotWidth * 0.56,
                54
            )

        for index in data.indices {

            let item =
                data[index]

            let centerX =
                rect.minX +
                slotWidth *
                CGFloat(index) +
                slotWidth / 2

            let barX =
                centerX -
                barWidth / 2

            let revenue =
                abs(item.revenue)

            let cost =
                abs(item.cost)

            let grossProfit =
                revenue - cost

            let revenueY =
                yPosition(revenue)

            let grossProfitY =
                yPosition(grossProfit)

            let isHovered =
                hoveredIndex == index

            let sameQuarter: Bool

            if let hoveredIndex =
                hoveredIndex {

                sameQuarter =
                    quarterNumber(
                        from:
                            item.periodTitle
                    ) ==
                    quarterNumber(
                        from:
                            data[hoveredIndex]
                                .periodTitle
                    )

            } else {

                sameQuarter = false
            }

            let highlighted =
                isHovered ||
                sameQuarter

            let dimmed =
                hoveredIndex != nil &&
                !highlighted

            let alpha: CGFloat =
                dimmed
                ? 0.12
                : 1.0

            let fillAlpha: CGFloat =
                isHovered
                ? 1.0
                : alpha

            if grossProfit >= 0 {

                // ALT PARÇA:
                // 0 -> Brüt Kar

                let grossProfitHeight =
                    max(
                        0,
                        grossProfitY -
                        zeroY
                    )

                let grossProfitRect =
                    CGRect(
                        x: barX,
                        y: zeroY,
                        width: barWidth,
                        height:
                            grossProfitHeight
                    )

                grossProfitFillColor
                    .withAlphaComponent(
                        grossProfitFillColor
                            .alphaComponent *
                        fillAlpha
                    )
                    .setFill()

                NSBezierPath(
                    rect: grossProfitRect
                ).fill()

                // ÜST PARÇA:
                // Brüt Kar -> Hasılat

                let costHeight =
                    max(
                        0,
                        revenueY -
                        grossProfitY
                    )

                let costRect =
                    CGRect(
                        x: barX,
                        y: grossProfitY,
                        width: barWidth,
                        height: costHeight
                    )

                revenueFillColor
                    .withAlphaComponent(
                        revenueFillColor
                            .alphaComponent *
                        fillAlpha
                    )
                    .setFill()

                NSBezierPath(
                    rect: costRect
                ).fill()

                // Sadece dış border.

                let outerBarRect =
                    CGRect(
                        x: barX,
                        y: zeroY,
                        width: barWidth,
                        height:
                            max(
                                0,
                                revenueY -
                                zeroY
                            )
                    )

                normalStrokeColor
                    .withAlphaComponent(
                        normalStrokeColor
                            .alphaComponent *
                        alpha
                    )
                    .setStroke()

                let outerPath =
                    NSBezierPath(
                        rect: outerBarRect
                    )

                outerPath.lineWidth = 0.8
                outerPath.stroke()

            } else {

                // BRÜT ZARAR

                let negativeTop =
                    zeroY

                let negativeBottom =
                    grossProfitY

                let negativeRect =
                    CGRect(
                        x: barX,
                        y: negativeBottom,
                        width: barWidth,
                        height:
                            max(
                                0,
                                negativeTop -
                                negativeBottom
                            )
                    )

                negativeGrossProfitFillColor
                    .withAlphaComponent(
                        negativeGrossProfitFillColor
                            .alphaComponent *
                        fillAlpha
                    )
                    .setFill()

                NSBezierPath(
                    rect: negativeRect
                ).fill()

                normalStrokeColor
                    .withAlphaComponent(
                        normalStrokeColor
                            .alphaComponent *
                        alpha
                    )
                    .setStroke()

                let negativePath =
                    NSBezierPath(
                        rect: negativeRect
                    )

                negativePath.lineWidth = 0.8
                negativePath.stroke()
            }

            drawGrossProfitLabel(
                grossProfit:
                    grossProfit,
                revenue:
                    revenue,
                centerX:
                    centerX,
                y:
                    revenueY + 6,
                highlighted:
                    highlighted,
                dimmed:
                    dimmed
            )
        }
    }

    // MARK: - Gross Profit Label

    private func drawGrossProfitLabel(
        grossProfit: Double,
        revenue: Double,
        centerX: CGFloat,
        y: CGFloat,
        highlighted: Bool,
        dimmed: Bool
    ) {

        let percentage: Double

        if revenue != 0 {

            percentage =
                (grossProfit / revenue) *
                100

        } else {

            percentage = 0
        }

        let text =
            String(
                format: "%.1f%%",
                percentage
            )

        let font =
            highlighted
            ? NSFont.systemFont(
                ofSize: 10,
                weight: .semibold
            )
            : NSFont.systemFont(
                ofSize: 9,
                weight: .regular
            )

        let color: NSColor

        if dimmed {

            color =
                labelColor
                    .withAlphaComponent(0.20)

        } else if highlighted {

            color = labelColor

        } else {

            color =
                labelColor
                    .withAlphaComponent(0.70)
        }

        let attributes:
            [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]

        let size =
            (text as NSString).size(
                withAttributes: attributes
            )

        (text as NSString).draw(
            at: NSPoint(
                x:
                    centerX -
                    size.width / 2,
                y: y
            ),
            withAttributes: attributes
        )
    }

    // MARK: - Period Labels

    private func drawPeriodLabels(
        in rect: CGRect
    ) {

        guard !data.isEmpty else {
            return
        }

        let slotWidth =
            rect.width /
            CGFloat(data.count)

        for index in data.indices {

            let item =
                data[index]

            let centerX =
                rect.minX +
                slotWidth *
                CGFloat(index) +
                slotWidth / 2

            let highlighted: Bool

            if let hoveredIndex =
                hoveredIndex {

                highlighted =
                    index ==
                    hoveredIndex ||
                    quarterNumber(
                        from:
                            item.periodTitle
                    ) ==
                    quarterNumber(
                        from:
                            data[hoveredIndex]
                                .periodTitle
                    )

            } else {

                highlighted = false
            }

            let dimmed =
                hoveredIndex != nil &&
                !highlighted

            let color: NSColor

            if dimmed {

                color =
                    secondaryLabelColor
                        .withAlphaComponent(0.20)

            } else if highlighted {

                color = labelColor

            } else {

                color =
                    secondaryLabelColor
            }

            let attributes:
                [NSAttributedString.Key: Any] = [
                    .font:
                        NSFont.systemFont(
                            ofSize: 9,
                            weight:
                                highlighted
                                ? .medium
                                : .regular
                        ),
                    .foregroundColor:
                        color
                ]

            let size =
                (item.periodTitle as NSString)
                    .size(
                        withAttributes:
                            attributes
                    )

            (item.periodTitle as NSString).draw(
                at: NSPoint(
                    x:
                        centerX -
                        size.width / 2,
                    y:
                        rect.minY - 30
                ),
                withAttributes:
                    attributes
            )
        }
    }

    // MARK: - Quarter

    private func quarterNumber(
        from periodTitle: String
    ) -> Int? {

        let numbers =
            periodTitle
                .split(
                    whereSeparator: {
                        !$0.isNumber
                    }
                )
                .compactMap {
                    Int($0)
                }

        guard numbers.count >= 2 else {
            return nil
        }

        switch numbers[1] {

        case 1:
            return 1

        case 2:
            return 2

        case 3:
            return 3

        case 4:
            return 4

        case 6:
            return 2

        case 9:
            return 3

        case 12:
            return 4

        default:
            return nil
        }
    }

    // MARK: - Number Formatting

    private func formattedValue(
        _ value: Double
    ) -> String {

        if abs(value) >= 1_000_000_000 {

            return String(
                format: "%.1fB",
                value /
                    1_000_000_000
            )
        }

        if abs(value) >= 1_000_000 {

            return String(
                format: "%.1fM",
                value /
                    1_000_000
            )
        }

        if abs(value) >= 1_000 {

            return String(
                format: "%.1fK",
                value /
                    1_000
            )
        }

        return String(
            format: "%.0f",
            value
        )
    }

    // MARK: - Compatibility API

    func draw(
        data: [DataPoint],
        in rect: CGRect,
        barWidth: CGFloat,
        barSpacing: CGFloat,
        maximumValue: Double
    ) {

        self.data =
            data.sorted {
                periodSortKey(
                    $0.periodTitle
                ) <
                periodSortKey(
                    $1.periodTitle
                )
            }

        needsDisplay = true
    }
}
