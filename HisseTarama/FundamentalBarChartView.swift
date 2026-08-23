import Cocoa
// MARK: - Bar Chart View

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

    private let positiveColor = NSColor(
        calibratedRed: 0.0,
        green: 0.45,
        blue: 0.20,
        alpha: 1.0
    )

    private let negativeColor = NSColor(
        calibratedRed: 0.80,
        green: 0.08,
        blue: 0.08,
        alpha: 1.0
    )

    private let zeroColor = NSColor.secondaryLabelColor

    // MARK: - Init

    override init(
        frame frameRect: NSRect
    ) {
        super.init(
            frame: frameRect
        )

        wantsLayer = true
    }

    required init?(
        coder: NSCoder
    ) {
        super.init(
            coder: coder
        )

        wantsLayer = true
    }

    // MARK: - Data

    func setData(
        items: [FinancialStatementItem],
        periods: [FinancialPeriod]
    ) {
        self.items = items

        // En eski dönem solda,
        // en yeni dönem sağda.
        self.periods = periods.sorted {
            if $0.year != $1.year {
                return $0.year < $1.year
            }

            return $0.quarter < $1.quarter
        }

        needsDisplay = true
    }

    // MARK: - Draw

    override func draw(
        _ dirtyRect: NSRect
    ) {
        super.draw(
            dirtyRect
        )

        guard !items.isEmpty,
              !periods.isEmpty
        else {
            return
        }

        guard let context =
            NSGraphicsContext
                .current?
                .cgContext
        else {
            return
        }

        drawBackground(
            context: context
        )

        drawChart(
            context: context
        )
    }

    // MARK: - Background

    private func drawBackground(
        context: CGContext
    ) {
        NSColor.controlBackgroundColor
            .setFill()

        bounds.fill()
    }

    // MARK: - Chart

    private func drawChart(
        context: CGContext
    ) {
        let chartRect = CGRect(
            x: leftMargin,
            y: bottomMargin,
            width: max(
                0,
                bounds.width
                    - leftMargin
                    - rightMargin
            ),
            height: max(
                0,
                bounds.height
                    - topMargin
                    - bottomMargin
            )
        )

        guard chartRect.width > 0,
              chartRect.height > 0
        else {
            return
        }

        let values = allValues()

        guard !values.isEmpty
        else {
            return
        }

        let maximum =
            max(
                values.max() ?? 0,
                0
            )

        let minimum =
            min(
                values.min() ?? 0,
                0
            )

        let range =
            maximum - minimum

        guard range > 0
        else {
            drawZeroLine(
                context: context,
                chartRect: chartRect
            )

            drawPeriodLabels(
                chartRect: chartRect
            )

            return
        }

        drawGrid(
            context: context,
            chartRect: chartRect,
            minimum: minimum,
            maximum: maximum
        )

        drawBars(
            context: context,
            chartRect: chartRect,
            minimum: minimum,
            maximum: maximum
        )

        drawPeriodLabels(
            chartRect: chartRect
        )
    }

    // MARK: - Values

    private func allValues() -> [Double] {

        var result: [Double] = []

        for item in items {

            for period in periods {

                guard let optionalValue =
                    item.values[period]
                else {
                    continue
                }

                guard let value =
                    optionalValue
                else {
                    continue
                }

                result.append(value)
            }
        }

        return result
    }

    // MARK: - Grid

    private func drawGrid(
        context: CGContext,
        chartRect: CGRect,
        minimum: Double,
        maximum: Double
    ) {

        let gridCount = 5

        for index in 0...gridCount {

            let ratio =
                CGFloat(index) /
                CGFloat(gridCount)

            let y =
                chartRect.minY +
                ratio *
                chartRect.height

            context.saveGState()

            context.setStrokeColor(
                NSColor.separatorColor.cgColor
            )

            context.setLineWidth(
                0.5
            )

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

            context.restoreGState()

            let value =
                minimum +
                (
                    maximum -
                    minimum
                ) *
                Double(ratio)

            drawValueLabel(
                value: value,
                at: CGPoint(
                    x: chartRect.minX - 8,
                    y: y
                )
            )
        }
    }

    // MARK: - Zero Line

    private func drawZeroLine(
        context: CGContext,
        chartRect: CGRect
    ) {

        let zeroY =
            chartRect.midY

        context.saveGState()

        context.setStrokeColor(
            zeroColor.cgColor
        )

        context.setLineWidth(
            1
        )

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

        context.restoreGState()
    }

    // MARK: - Bars

    private func drawBars(
        context: CGContext,
        chartRect: CGRect,
        minimum: Double,
        maximum: Double
    ) {

        let periodCount =
            periods.count

        guard periodCount > 0
        else {
            return
        }

        let seriesCount =
            max(
                items.count,
                1
            )

        let groupWidth =
            chartRect.width /
            CGFloat(periodCount)

        let totalBarWidth =
            groupWidth * 0.72

        let barWidth =
            totalBarWidth /
            CGFloat(seriesCount)

        let minValue =
            minimum

        let maxValue =
            maximum

        let calculatedRange =
            maxValue - minValue

        let safeRange =
            calculatedRange == 0.0
            ? 1.0
            : calculatedRange

        // Sıfırın grafik üzerindeki konumu

        let zeroRatio =
            (0.0 - minValue) /
            safeRange

        let zeroY =
            chartRect.minY +
            CGFloat(zeroRatio) *
            chartRect.height

        // MARK: Her dönem

        for periodIndex in 0..<periodCount {

            let period =
                periods[periodIndex]

            // MARK: Her finansal kalem

            for itemIndex in 0..<items.count {

                let item =
                    items[itemIndex]

                guard let optionalValue =
                    item.values[period]
                else {
                    continue
                }

                guard let value =
                    optionalValue
                else {
                    continue
                }

                let numericValue =
                    value

                let valueRatio =
                    (
                        numericValue -
                        minValue
                    ) /
                    safeRange

                let valueY =
                    chartRect.minY +
                    CGFloat(valueRatio) *
                    chartRect.height

                let x =
                    chartRect.minX +
                    CGFloat(periodIndex) *
                    groupWidth +
                    (
                        groupWidth -
                        totalBarWidth
                    ) / 2.0 +
                    CGFloat(itemIndex) *
                    barWidth

                let y =
                    min(
                        zeroY,
                        valueY
                    )

                let height =
                    abs(
                        valueY -
                        zeroY
                    )

                let rect =
                    CGRect(
                        x: x,
                        y: y,
                        width: max(
                            barWidth - 2.0,
                            1.0
                        ),
                        height: height
                    )

                // Pozitif / negatif renk

                let color =
                    chartColor(
                        value: numericValue
                    )

                color.setFill()

                let path =
                    NSBezierPath(
                        roundedRect: rect,
                        xRadius: 2.0,
                        yRadius: 2.0
                    )

                path.fill()
            }
        }
    }

    // MARK: - Period Labels

    private func drawPeriodLabels(
        chartRect: CGRect
    ) {

        let periodCount =
            periods.count

        guard periodCount > 0
        else {
            return
        }

        let groupWidth =
            chartRect.width /
            CGFloat(periodCount)

        for index in 0..<periodCount {

            let period =
                periods[index]

            let x =
                chartRect.minX +
                CGFloat(index) *
                groupWidth +
                groupWidth / 2

            let text =
                periodTitle(
                    period
                )

            let attributes:
                [NSAttributedString.Key: Any] = [

                    .font:
                        NSFont.systemFont(
                            ofSize: 10
                        ),

                    .foregroundColor:
                        NSColor.secondaryLabelColor
                ]

            let size =
                text.size(
                    withAttributes:
                        attributes
                )

            text.draw(
                at: CGPoint(
                    x:
                        x -
                        size.width / 2,

                    y:
                        chartRect.minY -
                        28
                ),

                withAttributes:
                    attributes
            )
        }
    }

    // MARK: - Value Label

    private func drawValueLabel(
        value: Double,
        at point: CGPoint
    ) {

        let text =
            formatValue(
                value
            )

        let attributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    NSFont.systemFont(
                        ofSize: 9
                    ),

                .foregroundColor:
                    NSColor.secondaryLabelColor
            ]

        let size =
            text.size(
                withAttributes:
                    attributes
            )

        text.draw(
            at: CGPoint(
                x:
                    point.x -
                    size.width,

                y:
                    point.y -
                    size.height / 2
            ),

            withAttributes:
                attributes
        )
    }

    // MARK: - Color

    private func chartColor(
        value: Double
    ) -> NSColor {

        if value > 0 {
            return positiveColor
        }

        if value < 0 {
            return negativeColor
        }

        return zeroColor
    }

    // MARK: - Format

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
        }

        if absolute >= 1_000_000 {

            return String(
                format: "%.1fM",
                value / 1_000_000
            )
        }

        if absolute >= 1_000 {

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

    // MARK: - Period Title

    private func periodTitle(
        _ period: FinancialPeriod
    ) -> String {

        return "\(period.year) Q\(period.quarter)"
    }
}

