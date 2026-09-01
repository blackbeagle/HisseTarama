import Cocoa

final class FundamentalBarChartView: NSView {

    // MARK: - Data

    private var items: [FinancialStatementItem] = []
    private var periods: [FinancialPeriod] = []

    // MARK: - Layout

    private let leftMargin: CGFloat = 80
    private let rightMargin: CGFloat = 20
    private let topMargin: CGFloat = 20
    private let bottomMargin: CGFloat = 55

    // MARK: - Colors

    private let positiveColor = NSColor.systemGreen
    private let negativeColor = NSColor.systemRed
    private let zeroColor = NSColor.secondaryLabelColor

    // MARK: - Scale

    private let scalePaddingRatio: Double = 0.08

    // MARK: - Hover

    /// Mouse'un bulunduğu finansal dönem.
    ///
    /// Örneğin mouse 2025 Q2 üzerindeyse:
    /// hoveredPeriodIndex = 2025 Q2'nin index'i
    private var hoveredPeriodIndex: Int?

    /// Mouse'un tam üzerinde olduğu gerçek bar.
    private var hoveredBarRect: CGRect?

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        updateTrackingAreas()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        wantsLayer = true
        updateTrackingAreas()
    }

    // MARK: - Data

    func setData(
        items: [FinancialStatementItem],
        periods: [FinancialPeriod]
    ) {
        self.items = items

        self.periods = periods.sorted {
            if $0.year != $1.year {
                return $0.year < $1.year
            }

            return $0.quarter < $1.quarter
        }

        hoveredPeriodIndex = nil
        hoveredBarRect = nil

        needsDisplay = true
    }

    // MARK: - Tracking Areas

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        trackingAreas.forEach {
            removeTrackingArea($0)
        }

        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .mouseEnteredAndExited,
            .activeInKeyWindow,
            .inVisibleRect
        ]

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: options,
            owner: self,
            userInfo: nil
        )

        addTrackingArea(trackingArea)
    }

    // MARK: - Mouse

    override func mouseMoved(with event: NSEvent) {
        let location = convert(
            event.locationInWindow,
            from: nil
        )

        updateHover(at: location)
    }

    override func mouseExited(with event: NSEvent) {
        clearHover()
    }

    // MARK: - Hover Calculation

    private func updateHover(at location: CGPoint) {

        guard !periods.isEmpty else {
            clearHover()
            return
        }

        let chartRect = chartRect()

        guard chartRect.width > 0,
              chartRect.height > 0,
              chartRect.contains(location) else {
            clearHover()
            return
        }

        let periodWidth =
            chartRect.width / CGFloat(periods.count)

        guard periodWidth > 0 else {
            clearHover()
            return
        }

        let relativeX =
            location.x - chartRect.minX

        let periodIndex =
            Int(relativeX / periodWidth)

        guard periodIndex >= 0,
              periodIndex < periods.count else {
            clearHover()
            return
        }

        let period = periods[periodIndex]

        // ---------------------------------------------------------
        // Önce bu dönemin gerçek bar alanlarını hesapla.
        // ---------------------------------------------------------

        let barRects = calculateBarRects(
            periodIndex: periodIndex,
            chartRect: chartRect
        )

        var hoveredRect: CGRect?

        for rect in barRects {

            if rect.contains(location) {
                hoveredRect = rect
                break
            }
        }

        // ---------------------------------------------------------
        // Quarter grubu her durumda hover edilir.
        //
        // Örneğin:
        //
        // 2023 Q2
        // 2024 Q2
        // 2025 Q2
        //
        // aynı anda vurgulanır.
        //
        // Exact bar ise ayrıca outline alır.
        // ---------------------------------------------------------

        let periodChanged =
            hoveredPeriodIndex != periodIndex

        let barChanged =
            hoveredBarRect != hoveredRect

        if periodChanged || barChanged {

            hoveredPeriodIndex = periodIndex
            hoveredBarRect = hoveredRect

            needsDisplay = true
        }

        _ = period
    }

    private func clearHover() {

        guard hoveredPeriodIndex != nil ||
                hoveredBarRect != nil else {
            return
        }

        hoveredPeriodIndex = nil
        hoveredBarRect = nil

        needsDisplay = true
    }

    // MARK: - Chart Rect

    private func chartRect() -> CGRect {

        CGRect(
            x: leftMargin,
            y: bottomMargin,
            width: max(
                0,
                bounds.width -
                    leftMargin -
                    rightMargin
            ),
            height: max(
                0,
                bounds.height -
                    topMargin -
                    bottomMargin
            )
        )
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawBackground()
        drawChart()
    }

    private func drawBackground() {

        NSColor.controlBackgroundColor.setFill()

        bounds.fill()
    }

    private func drawChart() {

        guard !periods.isEmpty else {
            return
        }

        let chartRect = chartRect()

        guard chartRect.width > 0,
              chartRect.height > 0 else {
            return
        }

        // ---------------------------------------------------------
        // Raw minimum / maximum
        // ---------------------------------------------------------

        var rawMinimum = 0.0
        var rawMaximum = 0.0

        for period in periods {

            for item in items {

                guard let numericValue =
                        item.value(for: period) else {
                    continue
                }

                rawMinimum =
                    min(rawMinimum, numericValue)

                rawMaximum =
                    max(rawMaximum, numericValue)
            }
        }

        let context =
            NSGraphicsContext.current!.cgContext

        // ---------------------------------------------------------
        // All values are zero
        // ---------------------------------------------------------

        if rawMinimum == 0 &&
            rawMaximum == 0 {

            let scale = makeNiceScale(
                minimum: -1,
                maximum: 1,
                desiredTickCount: 8
            )

          

            drawGrid(
                context: context,
                chartRect: chartRect,
                minimum: scale.minimum,
                maximum: scale.maximum,
                step: scale.step
            )

            drawBars(
                context: context,
                chartRect: chartRect,
                minimum: scale.minimum,
                maximum: scale.maximum
            )

            drawZeroLine(
                context: context,
                chartRect: chartRect,
                minimum: scale.minimum,
                maximum: scale.maximum
            )

            drawPeriodLabels(
                chartRect: chartRect
            )

            return
        }

        // ---------------------------------------------------------
        // Scale padding
        // ---------------------------------------------------------

        let rawRange =
            max(
                rawMaximum - rawMinimum,
                1
            )

        var minimum =
            rawMinimum -
            rawRange * scalePaddingRatio

        var maximum =
            rawMaximum +
            rawRange * scalePaddingRatio

        // Zero always belongs to the scale.

        minimum =
            min(minimum, 0)

        maximum =
            max(maximum, 0)

        // ---------------------------------------------------------
        // Nice scale
        // ---------------------------------------------------------

        let scale = makeNiceScale(
            minimum: minimum,
            maximum: maximum,
            desiredTickCount: 8
        )

    

        // ---------------------------------------------------------
        // Grid
        // ---------------------------------------------------------

        drawGrid(
            context: context,
            chartRect: chartRect,
            minimum: scale.minimum,
            maximum: scale.maximum,
            step: scale.step
        )

        // ---------------------------------------------------------
        // Bars
        // ---------------------------------------------------------

        drawBars(
            context: context,
            chartRect: chartRect,
            minimum: scale.minimum,
            maximum: scale.maximum
        )

        // ---------------------------------------------------------
        // Zero line
        // ---------------------------------------------------------

        drawZeroLine(
            context: context,
            chartRect: chartRect,
            minimum: scale.minimum,
            maximum: scale.maximum
        )

        // ---------------------------------------------------------
        // Period labels
        // ---------------------------------------------------------

        drawPeriodLabels(
            chartRect: chartRect
        )
    }

   

    // MARK: - Bars

    private func drawBars(
        context: CGContext,
        chartRect: CGRect,
        minimum: Double,
        maximum: Double
    ) {

        guard !periods.isEmpty else {
            return
        }

        let periodWidth =
            chartRect.width /
            CGFloat(periods.count)

        let zeroY =
            chartRect.minY +
            CGFloat(
                (0 - minimum) /
                (maximum - minimum)
            ) *
            chartRect.height

        for periodIndex in periods.indices {

            let period =
                periods[periodIndex]

            let periodX =
                chartRect.minX +
                CGFloat(periodIndex) *
                periodWidth

            // -----------------------------------------------------
            // Bu dönem için değeri bulunan kalemler.
            // -----------------------------------------------------

            let validItems =
                items.compactMap {
                    item -> (
                        FinancialStatementItem,
                        Double
                    )? in

                    guard let numericValue =
                            item.value(
                                for: period
                            ) else {
                        return nil
                    }

                    return (
                        item,
                        numericValue
                    )
                }

            guard !validItems.isEmpty else {
                continue
            }

            let barCount =
                validItems.count

            let groupWidth =
                periodWidth * 0.72

            let barGap: CGFloat = 6

            let totalGap =
                CGFloat(
                    max(barCount - 1, 0)
                ) *
                barGap

            let barWidth =
                max(
                    2,
                    (
                        groupWidth -
                        totalGap
                    ) /
                    CGFloat(barCount)
                )

            let groupX =
                periodX +
                (periodWidth - groupWidth) / 2

            // -----------------------------------------------------
            // Bars
            // -----------------------------------------------------

            for itemIndex in validItems.indices {

                let numericValue =
                    validItems[itemIndex].1

                let barX =
                    groupX +
                    CGFloat(itemIndex) *
                    (barWidth + barGap)

                let valueY =
                    chartRect.minY +
                    CGFloat(
                        (numericValue - minimum) /
                        (maximum - minimum)
                    ) *
                    chartRect.height

                let y =
                    min(
                        zeroY,
                        valueY
                    )

                let height =
                    max(
                        abs(valueY - zeroY),
                        1
                    )

                let rect = CGRect(
                    x: barX,
                    y: y,
                    width: barWidth,
                    height: height
                )

                // -------------------------------------------------
                // Bar
                // -------------------------------------------------

                let path =
                    NSBezierPath(
                        roundedRect: rect,
                        xRadius: 3,
                        yRadius: 3
                    )

                let isSameQuarter: Bool = {

                    guard let hoveredPeriodIndex = hoveredPeriodIndex,
                          hoveredPeriodIndex < periods.count else {
                        return true
                    }

                    return periods[periodIndex].quarter ==
                        periods[hoveredPeriodIndex].quarter
                }()

                let barAlpha: CGFloat = {

                    guard hoveredPeriodIndex != nil else {
                        return 1.0
                    }

                    return isSameQuarter ? 1.0 : 0.30
                }()

                if numericValue >= 0 {

                    positiveColor
                        .withAlphaComponent(barAlpha)
                        .setFill()

                } else {

                    negativeColor
                        .withAlphaComponent(barAlpha)
                        .setFill()
                }

                path.fill()

                // -------------------------------------------------
                // Value label
                // -------------------------------------------------

                drawBarValueLabel(
                    value: numericValue,
                    rect: rect,
                    zeroY: zeroY
                )

                // -------------------------------------------------
                // Exact hovered bar outline
                // -------------------------------------------------

                if let hoveredBarRect = hoveredBarRect,
                   hoveredBarRect.equalTo(rect) {

                    let outlineRect =
                        rect.insetBy(
                            dx: 0.5,
                            dy: 0.5
                        )

                    let outlinePath =
                        NSBezierPath(
                            roundedRect: outlineRect,
                            xRadius: 3,
                            yRadius: 3
                        )

                    NSColor.labelColor
                        .withAlphaComponent(0.70)
                        .setStroke()

                    outlinePath.lineWidth = 1.5

                    outlinePath.stroke()
                }
            }
        }
    }

    // MARK: - Calculate Bar Rects

    private func calculateBarRects(
        periodIndex: Int,
        chartRect: CGRect
    ) -> [CGRect] {

        guard periodIndex >= 0,
              periodIndex < periods.count else {
            return []
        }

        let period =
            periods[periodIndex]

        let periodWidth =
            chartRect.width /
            CGFloat(periods.count)

        let validItems =
            items.compactMap {
                item -> (
                    FinancialStatementItem,
                    Double
                )? in

                guard let numericValue =
                        item.value(
                            for: period
                        ) else {
                    return nil
                }

                return (
                    item,
                    numericValue
                )
            }

        guard !validItems.isEmpty else {
            return []
        }

        let barCount =
            validItems.count

        let groupWidth =
            periodWidth * 0.72

        let barGap: CGFloat = 6

        let totalGap =
            CGFloat(
                max(barCount - 1, 0)
            ) *
            barGap

        let barWidth =
            max(
                2,
                (
                    groupWidth -
                    totalGap
                ) /
                CGFloat(barCount)
            )

        let groupX =
            chartRect.minX +
            CGFloat(periodIndex) *
            periodWidth +
            (periodWidth - groupWidth) / 2

        // ---------------------------------------------------------
        // Gerçek dikey bar koordinatlarını bulabilmek için
        // aynı ölçeği kullanıyoruz.
        //
        // Burada sadece hover tespiti yapıldığı için, değer
        // etiketlerinin veya çizimin kendisinin ölçeğini değiştirmiyoruz.
        // ---------------------------------------------------------

        var rawMinimum = 0.0
        var rawMaximum = 0.0

        for currentPeriod in periods {

            for item in items {

                guard let numericValue =
                        item.value(
                            for: currentPeriod
                        ) else {
                    continue
                }

                rawMinimum =
                    min(
                        rawMinimum,
                        numericValue
                    )

                rawMaximum =
                    max(
                        rawMaximum,
                        numericValue
                    )
            }
        }

        let rawRange =
            max(
                rawMaximum - rawMinimum,
                1
            )

        var minimum =
            rawMinimum -
            rawRange * scalePaddingRatio

        var maximum =
            rawMaximum +
            rawRange * scalePaddingRatio

        minimum =
            min(minimum, 0)

        maximum =
            max(maximum, 0)

        let scale =
            makeNiceScale(
                minimum: minimum,
                maximum: maximum,
                desiredTickCount: 8
            )

        let zeroY =
            chartRect.minY +
            CGFloat(
                (0 - scale.minimum) /
                (scale.maximum - scale.minimum)
            ) *
            chartRect.height

        var rects: [CGRect] = []

        for itemIndex in validItems.indices {

            let numericValue =
                validItems[itemIndex].1

            let barX =
                groupX +
                CGFloat(itemIndex) *
                (barWidth + barGap)

            let valueY =
                chartRect.minY +
                CGFloat(
                    (numericValue - scale.minimum) /
                    (scale.maximum - scale.minimum)
                ) *
                chartRect.height

            let y =
                min(
                    zeroY,
                    valueY
                )

            let height =
                max(
                    abs(valueY - zeroY),
                    1
                )

            let rect = CGRect(
                x: barX,
                y: y,
                width: barWidth,
                height: height
            )

            rects.append(rect)
        }

        return rects
    }

    // MARK: - Grid

    private func drawGrid(
        context: CGContext,
        chartRect: CGRect,
        minimum: Double,
        maximum: Double,
        step: Double
    ) {

        guard step > 0 else {
            return
        }

        let firstTick =
            ceil(minimum / step) * step

        var value = firstTick

        while value <=
                maximum +
                step * 0.001 {

            let y =
                chartRect.minY +
                CGFloat(
                    (value - minimum) /
                    (maximum - minimum)
                ) *
                chartRect.height

            // Zero çizgisini burada çizmiyoruz.
            // Aşağıda ayrı olarak çiziyoruz.

            if abs(value) >
                step * 0.001 {

                context.setStrokeColor(
                    NSColor.separatorColor
                        .withAlphaComponent(0.35)
                        .cgColor
                )

                context.setLineWidth(0.5)

                context.move(
                    to: CGPoint(
                        x: chartRect.minX,
                        y: y
                    )
                )

                context.addLine(
                    to: CGPoint(
                        x: chartRect.maxX,
                        y: y
                    )
                )

                context.strokePath()
            }

            drawValueLabel(
                value: value,
                y: y,
                chartRect: chartRect
            )

            value += step
        }
    }

    // MARK: - Zero Line

    private func drawZeroLine(
        context: CGContext,
        chartRect: CGRect,
        minimum: Double,
        maximum: Double
    ) {

        guard minimum <= 0,
              maximum >= 0 else {
            return
        }

        let zeroY =
            chartRect.minY +
            CGFloat(
                (0 - minimum) /
                (maximum - minimum)
            ) *
            chartRect.height

        context.setStrokeColor(
            zeroColor.cgColor
        )

        context.setLineWidth(1.0)

        context.move(
            to: CGPoint(
                x: chartRect.minX,
                y: zeroY
            )
        )

        context.addLine(
            to: CGPoint(
                x: chartRect.maxX,
                y: zeroY
            )
        )

        context.strokePath()
    }

    // MARK: - Period Labels

    private func drawPeriodLabels(
        chartRect: CGRect
    ) {

        guard !periods.isEmpty else {
            return
        }

        let periodWidth =
            chartRect.width /
            CGFloat(periods.count)

        for index in periods.indices {

            let period =
                periods[index]

            let text =
                "\(period.year) Q\(period.quarter)"

            let isHighlighted: Bool = {

                guard let hoveredPeriodIndex = hoveredPeriodIndex,
                      hoveredPeriodIndex <
                        periods.count else {
                    return false
                }

                return periods[index].quarter ==
                    periods[hoveredPeriodIndex].quarter
            }()

            let attributes:
                [NSAttributedString.Key: Any] = [

                    .font:
                        NSFont.systemFont(
                            ofSize: 12,
                            weight:
                                isHighlighted
                                ? .semibold
                                : .regular
                        ),

                    .foregroundColor:
                        isHighlighted
                        ? NSColor.labelColor
                        : NSColor.secondaryLabelColor
                ]

            let size =
                text.size(
                    withAttributes: attributes
                )

            let x =
                chartRect.minX +
                CGFloat(index) *
                periodWidth +
                (
                    periodWidth -
                    size.width
                ) / 2

            let y =
                chartRect.minY -
                size.height -
                10

            text.draw(
                at: CGPoint(
                    x: x,
                    y: y
                ),
                withAttributes: attributes
            )
        }
    }

    // MARK: - Bar Value Label

    private func drawBarValueLabel(
        value: Double,
        rect: CGRect,
        zeroY: CGFloat
    ) {

        let text =
            formatValue(value)

        let attributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    NSFont.systemFont(
                        ofSize: 14,
                        weight: .medium
                    ),

                .foregroundColor:
                    NSColor.labelColor
            ]

        let size =
            text.size(
                withAttributes: attributes
            )

        let spacing: CGFloat = 4

        let x =
            rect.midX -
            size.width / 2

        let y: CGFloat

        if value >= 0 {

            y =
                rect.maxY +
                spacing

        } else {

            y =
                rect.minY -
                size.height -
                spacing
        }

        text.draw(
            at: CGPoint(
                x: x,
                y: y
            ),
            withAttributes: attributes
        )

        _ = zeroY
    }

    // MARK: - Axis Value Label

    private func drawValueLabel(
        value: Double,
        y: CGFloat,
        chartRect: CGRect
    ) {

        let text =
            formatValue(value)

        let attributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    NSFont.systemFont(
                        ofSize: 11
                    ),

                .foregroundColor:
                    NSColor.secondaryLabelColor
            ]

        let size =
            text.size(
                withAttributes: attributes
            )

        let x =
            chartRect.minX -
            size.width -
            8

        let drawY =
            y -
            size.height / 2

        text.draw(
            at: CGPoint(
                x: x,
                y: drawY
            ),
            withAttributes: attributes
        )
    }

    // MARK: - Formatting

    private func formatValue(
        _ value: Double
    ) -> String {

        let absolute =
            abs(value)

        if absolute >= 1_000_000_000 {

            return String(
                format: "%.1fB",
                value / 1_000_000_000
            )

        } else if absolute >= 1_000_000 {

            return String(
                format: "%.1fM",
                value / 1_000_000
            )

        } else if absolute >= 1_000 {

            return String(
                format: "%.1fK",
                value / 1_000
            )
        }

        return String(
            format: "%.0f",
            value
        )
    }

    // MARK: - Nice Scale

    private func makeNiceScale(
        minimum: Double,
        maximum: Double,
        desiredTickCount: Int
    ) -> (
        minimum: Double,
        maximum: Double,
        step: Double
    ) {

        let range =
            maximum - minimum

        guard range > 0 else {

            return (
                minimum: minimum - 1,
                maximum: maximum + 1,
                step: 1
            )
        }

        let roughStep =
            range /
            Double(
                max(
                    desiredTickCount,
                    1
                )
            )

        let magnitude =
            pow(
                10,
                floor(
                    log10(roughStep)
                )
            )

        let normalized =
            roughStep / magnitude

        let niceNormalized: Double

        if normalized <= 1 {

            niceNormalized = 1

        } else if normalized <= 2 {

            niceNormalized = 2

        } else if normalized <= 5 {

            niceNormalized = 5

        } else {

            niceNormalized = 10
        }

        let step =
            niceNormalized *
            magnitude

        let niceMinimum =
            floor(
                minimum / step
            ) * step

        let niceMaximum =
            ceil(
                maximum / step
            ) * step

        return (
            minimum: niceMinimum,
            maximum: niceMaximum,
            step: step
        )
    }
}


