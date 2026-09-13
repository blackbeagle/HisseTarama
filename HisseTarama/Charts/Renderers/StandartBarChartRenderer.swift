import Cocoa

final class StandartBarChartRenderer: NSView {

    struct DataPoint {
        let periodTitle: String
        let value: Double
    }

    // MARK: - Data

    private var data: [DataPoint] = []

    private var hoveredIndex: Int?
    private var hoveredPeriodKey: Int?

    private var trackingArea: NSTrackingArea?

    private var isUSDMode = false

    private var chartTitle: String = "Finansal Grafik"


    // MARK: - Layout

    // Çerçevenin sağ ve sol kenarlardan uzaklığı.
    // Artırırsan çerçeve daha dar olur.
    private let outerHorizontalMargin: CGFloat = 34

    // Çerçevenin üst ve alt kenarlardan uzaklığı.
    // Artırırsan çerçeve biraz daha kısa olur.
    private let outerVerticalMargin: CGFloat = 14

    // Grafik çizim alanının iç boşlukları.

    private let leftMargin: CGFloat = 66
    private let rightMargin: CGFloat = 28

    private let topMargin: CGFloat = 68
    private let bottomMargin: CGFloat = 68

    // Çizim alanının kendisine ek küçük boşluk.
    private let plotHorizontalInset: CGFloat = 10
    private let plotVerticalInset: CGFloat = 10


    // MARK: - Colors

    private let positiveColor =
        NSColor.systemGreen.withAlphaComponent(0.45)

    private let negativeColor =
        NSColor.systemRed.withAlphaComponent(0.45)

    private let gridColor =
        NSColor.white.withAlphaComponent(0.16)

    private let zeroLineColor =
        NSColor.white.withAlphaComponent(0.72)

    private let borderColor =
        NSColor.separatorColor.withAlphaComponent(0.90)

    private let labelColor =
        NSColor.labelColor

    private let secondaryLabelColor =
        NSColor.secondaryLabelColor


    // MARK: - Data API

    func setData(
        _ data: [DataPoint]
    ) {

        self.data =
            data.sorted {
                periodSortKey(
                    $0.periodTitle
                )
                <
                periodSortKey(
                    $1.periodTitle
                )
            }

        hoveredIndex = nil
        hoveredPeriodKey = nil

        needsDisplay = true

        updateTrackingArea()
    }


    func clear() {

        data.removeAll()

        hoveredIndex = nil
        hoveredPeriodKey = nil
    }


    func setCurrency(
        isUSD: Bool
    ) {

        isUSDMode = isUSD

        needsDisplay = true
    }


    // MARK: - Title

    func setTitle(
        _ title: String
    ) {

        chartTitle = title

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
            return (
                Int.max,
                Int.max
            )
        }

        let year =
            numbers[0]

        let period =
            numbers[1]

        let quarter =
            normalizedQuarter(
                period
            )

        return (
            year,
            quarter
        )
    }


    // MARK: - Quarter Group

    private func normalizedQuarter(
        _ period: Int
    ) -> Int {

        switch period {

        case 1:
            return 1

        case 2, 6:
            return 2

        case 3, 9:
            return 3

        case 4, 12:
            return 4

        default:
            return period
        }
    }


    private func periodGroupKey(
        _ periodTitle: String
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

        return normalizedQuarter(
            numbers[1]
        )
    }


    // MARK: - Tracking

    override func updateTrackingAreas() {

        super.updateTrackingAreas()

        if let trackingArea =
            trackingArea {

            removeTrackingArea(
                trackingArea
            )
        }

        let area =
            NSTrackingArea(
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

        addTrackingArea(
            area
        )
    }


    private func updateTrackingArea() {

        if let trackingArea =
            trackingArea {

            removeTrackingArea(
                trackingArea
            )
        }

        let area =
            NSTrackingArea(
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

        addTrackingArea(
            area
        )
    }


    override func mouseEntered(
        with event: NSEvent
    ) {

        updateHover(
            with: event
        )
    }


    override func mouseMoved(
        with event: NSEvent
    ) {

        updateHover(
            with: event
        )
    }


    override func mouseExited(
        with event: NSEvent
    ) {

        if hoveredIndex != nil ||
            hoveredPeriodKey != nil {

            hoveredIndex = nil
            hoveredPeriodKey = nil

            needsDisplay = true
        }
    }


    private func updateHover(
        with event: NSEvent
    ) {

        let location =
            convert(
                event.locationInWindow,
                from: nil
            )

        let index =
            barIndex(
                at: location
            )

        guard let index = index else {

            if hoveredIndex != nil ||
                hoveredPeriodKey != nil {

                hoveredIndex = nil
                hoveredPeriodKey = nil

                needsDisplay = true
            }

            return
        }

        let newPeriodKey =
            periodGroupKey(
                data[index].periodTitle
            )

        if hoveredIndex != index ||
            hoveredPeriodKey != newPeriodKey {

            hoveredIndex = index
            hoveredPeriodKey = newPeriodKey

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
            makeOuterRect()

        let plottingRect =
            makePlottingRect(
                in: outerRect
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
                slotWidth *
                CGFloat(index) +
                slotWidth / 2

            let hitRect =
                CGRect(
                    x:
                        centerX -
                        barWidth / 2,

                    y:
                        plottingRect.minY,

                    width:
                        barWidth,

                    height:
                        plottingRect.height
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

        super.draw(
            dirtyRect
        )

        guard !data.isEmpty else {
            return
        }

        let outerRect =
            makeOuterRect()

        drawChart(
            in: outerRect
        )
    }


    // MARK: - Outer Rect

    private func makeOuterRect()
        -> CGRect {

        CGRect(
            x:
                bounds.minX +
                outerHorizontalMargin,

            y:
                bounds.minY +
                outerVerticalMargin,

            width:
                max(
                    0,
                    bounds.width -
                    outerHorizontalMargin * 2
                ),

            height:
                max(
                    0,
                    bounds.height -
                    outerVerticalMargin * 2
                )
        )
    }


    private func drawChart(
        in outerRect: CGRect
    ) {

        let plottingRect =
            makePlottingRect(
                in: outerRect
            )

        guard plottingRect.width > 0,
              plottingRect.height > 0 else {

            return
        }

        drawOuterBorder(
            in: outerRect
        )

        drawTitle(
            in: outerRect
        )

        let scale =
            calculateScale()

        drawGrid(
            in: plottingRect,
            minimumValue: scale.minimum,
            maximumValue: scale.maximum
        )

        drawBars(
            in: plottingRect,
            minimumValue: scale.minimum,
            maximumValue: scale.maximum
        )

        drawPeriodLabels(
            in: plottingRect
        )
    }


    // MARK: - Plotting Rect

    private func makePlottingRect(
        in outerRect: CGRect
    ) -> CGRect {

        let baseRect =
            CGRect(
                x:
                    outerRect.minX +
                    leftMargin,

                y:
                    outerRect.minY +
                    bottomMargin,

                width:
                    max(
                        0,
                        outerRect.width -
                        leftMargin -
                        rightMargin
                    ),

                height:
                    max(
                        0,
                        outerRect.height -
                        topMargin -
                        bottomMargin
                    )
            )

        return baseRect.insetBy(
            dx: plotHorizontalInset,
            dy: plotVerticalInset
        )
    }


    // MARK: - Border

    private func drawOuterBorder(
        in rect: CGRect
    ) {

        let path =
            NSBezierPath(
                roundedRect:
                    rect,
                xRadius:
                    8,
                yRadius:
                    8
            )

        borderColor.setStroke()

        path.lineWidth = 1.4

        path.stroke()
    }


    // MARK: - Title

    private func drawTitle(
        in rect: CGRect
    ) {

        let title =
            chartTitle
                .uppercased(
                    with:
                        Locale(
                            identifier:
                                "tr_TR"
                        )
                )

        let attributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    NSFont.systemFont(
                        ofSize: 14,
                        weight: .semibold
                    ),

                .foregroundColor:
                    labelColor
            ]

        let size =
            (title as NSString).size(
                withAttributes:
                    attributes
            )

        (title as NSString).draw(
            at:
                NSPoint(
                    x:
                        rect.midX -
                        size.width / 2,

                    y:
                        rect.maxY -
                        40
                ),

            withAttributes:
                attributes
        )
    }


    // MARK: - Scale

    private func calculateScale()
        -> (
            minimum: Double,
            maximum: Double
        ) {

        guard !data.isEmpty else {
            return (
                0,
                1
            )
        }

        let maximumAbsoluteValue =
            data
                .map {
                    abs(
                        $0.value
                    )
                }
                .max() ?? 0

        if maximumAbsoluteValue == 0 {

            return (
                -1,
                1
            )
        }

        let paddedMaximum =
            maximumAbsoluteValue * 1.18

        let magnitude =
            niceAxisMagnitude(
                paddedMaximum
            )

        let hasPositive =
            data.contains {
                $0.value > 0
            }

        let hasNegative =
            data.contains {
                $0.value < 0
            }

        if hasPositive &&
            !hasNegative {

            return (
                0,
                magnitude
            )
        }

        if hasNegative &&
            !hasPositive {

            return (
                -magnitude,
                0
            )
        }

        return (
            -magnitude,
            magnitude
        )
    }


    private func niceAxisMagnitude(
        _ value: Double
    ) -> Double {

        guard value > 0 else {
            return 1
        }

        let exponent =
            floor(
                log10(
                    value
                )
            )

        let power =
            pow(
                10,
                exponent
            )

        let normalized =
            value /
            power

        let niceNormalized:
            Double

        if normalized <= 1 {

            niceNormalized = 1

        } else if normalized <= 2 {

            niceNormalized = 2

        } else if normalized <= 5 {

            niceNormalized = 5

        } else {

            niceNormalized = 10
        }

        return
            niceNormalized *
            power
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

            let path =
                NSBezierPath()

            path.move(
                to:
                    NSPoint(
                        x:
                            rect.minX,
                        y:
                            y
                    )
            )

            path.line(
                to:
                    NSPoint(
                        x:
                            rect.maxX,
                        y:
                            y
                    )
            )

            if abs(value) <
                range * 0.0001 {

                zeroLineColor.setStroke()

                path.lineWidth = 1.2

            } else {

                gridColor.setStroke()

                path.lineWidth = 0.6
            }

            path.stroke()

            drawAxisValue(
                value,
                at:
                    y,
                in:
                    rect
            )
        }
    }


    private func drawAxisValue(
        _ value: Double,
        at y: CGFloat,
        in rect: CGRect
    ) {

        let text =
            formattedValue(
                value
            )

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
            (text as NSString).size(
                withAttributes:
                    attributes
            )

        (text as NSString).draw(
            at:
                NSPoint(
                    x:
                        rect.minX -
                        10 -
                        size.width,

                    y:
                        y -
                        size.height / 2
                ),

            withAttributes:
                attributes
        )
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
                    (
                        value -
                        minimumValue
                    )
                    /
                    range
                )

            return
                rect.minY +
                rect.height *
                ratio
        }

        let zeroY =
            yPosition(
                0
            )

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

            let valueY =
                yPosition(
                    item.value
                )

            let isPositive =
                item.value >= 0

            // Aynı çeyrek bütün yıllarda
            // birlikte vurgulanır.
            let isHovered =
                hoveredPeriodKey != nil &&
                periodGroupKey(
                    item.periodTitle
                )
                ==
                hoveredPeriodKey

            let dimmed =
                hoveredPeriodKey != nil &&
                !isHovered

            let fillAlpha:
                CGFloat

            if isHovered {

                fillAlpha = 0.90

            } else if dimmed {

                fillAlpha = 0.12

            } else {

                fillAlpha = 0.45
            }

            let barRect:
                CGRect

            if isPositive {

                barRect =
                    CGRect(
                        x:
                            centerX -
                            barWidth / 2,

                        y:
                            zeroY,

                        width:
                            barWidth,

                        height:
                            max(
                                0,
                                valueY -
                                zeroY
                            )
                    )

                positiveColor
                    .withAlphaComponent(
                        fillAlpha
                    )
                    .setFill()

            } else {

                barRect =
                    CGRect(
                        x:
                            centerX -
                            barWidth / 2,

                        y:
                            valueY,

                        width:
                            barWidth,

                        height:
                            max(
                                0,
                                zeroY -
                                valueY
                            )
                    )

                negativeColor
                    .withAlphaComponent(
                        fillAlpha
                    )
                    .setFill()
            }

            NSBezierPath(
                roundedRect:
                    barRect,
                xRadius:
                    2,
                yRadius:
                    2
            ).fill()

            drawValueLabel(
                item.value,

                centerX:
                    centerX,

                valueY:
                    valueY,

                zeroY:
                    zeroY,

                isPositive:
                    isPositive,

                highlighted:
                    isHovered,

                dimmed:
                    dimmed
            )
        }
    }


    // MARK: - Value Labels

    private func drawValueLabel(
        _ value: Double,
        centerX: CGFloat,
        valueY: CGFloat,
        zeroY: CGFloat,
        isPositive: Bool,
        highlighted: Bool,
        dimmed: Bool
    ) {

        let text =
            formattedValue(
                value,
                includeCurrency:
                    true
            )

        let font =
            highlighted

            ? NSFont.systemFont(
                ofSize:
                    10,
                weight:
                    .semibold
            )

            : NSFont.systemFont(
                ofSize:
                    9,
                weight:
                    .regular
            )

        let alpha:
            CGFloat

        if dimmed {

            alpha = 0.20

        } else if highlighted {

            alpha = 1.0

        } else {

            alpha = 0.72
        }

        let attributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    font,

                .foregroundColor:
                    labelColor
                        .withAlphaComponent(
                            alpha
                        )
            ]

        let size =
            (text as NSString).size(
                withAttributes:
                    attributes
            )

        let verticalSpacing:
            CGFloat = 5

        let y:
            CGFloat

        if isPositive {

            y =
                valueY +
                verticalSpacing

        } else {

            y =
                valueY -
                size.height -
                verticalSpacing
        }

        (text as NSString).draw(
            at:
                NSPoint(
                    x:
                        centerX -
                        size.width / 2,

                    y:
                        y
                ),

            withAttributes:
                attributes
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

            let isHovered =
                hoveredPeriodKey != nil &&
                periodGroupKey(
                    item.periodTitle
                )
                ==
                hoveredPeriodKey

            let dimmed =
                hoveredPeriodKey != nil &&
                !isHovered

            let color:
                NSColor

            if dimmed {

                color =
                    secondaryLabelColor
                        .withAlphaComponent(
                            0.20
                        )

            } else if isHovered {

                color =
                    labelColor

            } else {

                color =
                    secondaryLabelColor
            }

            let attributes:
                [NSAttributedString.Key: Any] = [

                    .font:
                        NSFont.systemFont(
                            ofSize:
                                9,

                            weight:
                                isHovered
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

            (
                item.periodTitle
                as NSString
            ).draw(
                at:
                    NSPoint(
                        x:
                            centerX -
                            size.width / 2,

                        y:
                            rect.minY -
                            30
                    ),

                withAttributes:
                    attributes
            )
        }
    }


    // MARK: - Number Formatting

    private func formattedValue(
        _ value: Double,
        includeCurrency: Bool = false
    ) -> String {

        let absoluteValue =
            abs(value)

        let number:
            String

        if absoluteValue >=
            1_000_000_000 {

            number =
                String(
                    format:
                        "%.1fB",

                    absoluteValue /
                        1_000_000_000
                )

        } else if absoluteValue >=
                    1_000_000 {

            number =
                String(
                    format:
                        "%.1fM",

                    absoluteValue /
                        1_000_000
                )

        } else if absoluteValue >=
                    1_000 {

            number =
                String(
                    format:
                        "%.1fK",

                    absoluteValue /
                        1_000
                )

        } else {

            number =
                String(
                    format:
                        "%.0f",

                    absoluteValue
                )
        }

        let signedNumber:
            String

        if value < 0 {

            signedNumber =
                "-" +
                number

        } else {

            signedNumber =
                number
        }

        if includeCurrency &&
            isUSDMode {

            return
                "$" +
                signedNumber
        }

        return signedNumber
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
                )
                <
                periodSortKey(
                    $1.periodTitle
                )
            }

        hoveredIndex = nil
        hoveredPeriodKey = nil

        needsDisplay = true
    }
}
