
import Cocoa

// MARK: - Bar Chart View

final class FundamentalBarChartView: NSView {

    // MARK: - Data

    private var items: [FinancialStatementItem] = []
    private var periods: [FinancialPeriod] = []

    // MARK: - Layout

    // Daha kompakt ve finansal terminal benzeri görünüm.
    private let leftMargin: CGFloat = 58
    private let rightMargin: CGFloat = 10
    private let topMargin: CGFloat = 8
    private let bottomMargin: CGFloat = 32

    // Grafik üst / alt nefes payı.
    private let scalePaddingRatio: Double = 0.08

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

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
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

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

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
        NSColor.controlBackgroundColor.setFill()
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

        let rawMaximum =
            max(
                values.max() ?? 0,
                0
            )

        let rawMinimum =
            min(
                values.min() ?? 0,
                0
            )

        let rawRange =
            rawMaximum - rawMinimum

        // Tüm değerler sıfır ise.
        guard rawRange > 0
        else {

            drawZeroLine(
                context: context,
                chartRect: chartRect,
                minimum: -1,
                maximum: 1
            )

            drawPeriodLabels(
                chartRect: chartRect
            )

            return
        }

        // -------------------------------------------------
        // Grafik ölçeğine nefes payı ekle.
        // -------------------------------------------------

        let padding =
            rawRange * scalePaddingRatio

        let minimum =
            rawMinimum - padding

        let maximum =
            rawMaximum + padding

        let range =
            maximum - minimum

        guard range > 0
        else {
            return
        }

        // -------------------------------------------------
        // Profesyonel görünümlü grid ölçeği.
        // -------------------------------------------------

        let scale =
            makeNiceScale(
                minimum: minimum,
                maximum: maximum,
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

        // 0 çizgisi grid çizgilerinden sonra çiziliyor.
        // Böylece daha belirgin kalıyor.
        drawZeroLine(
            context: context,
            chartRect: chartRect,
            minimum: scale.minimum,
            maximum: scale.maximum
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

    // MARK: - Nice Scale

    private struct NiceScale {

        let minimum: Double
        let maximum: Double
        let step: Double
    }

    private func makeNiceScale(
        minimum: Double,
        maximum: Double,
        desiredTickCount: Int
    ) -> NiceScale {

        let range =
            maximum - minimum

        guard range > 0 else {
            return NiceScale(
                minimum: minimum,
                maximum: maximum,
                step: 1
            )
        }

        let rawStep =
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
                    log10(rawStep)
                )
            )

        let normalized =
            rawStep / magnitude

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

        return NiceScale(
            minimum: niceMinimum,
            maximum: niceMaximum,
            step: step
        )
    }

    // MARK: - Grid

    private func drawGrid(
        context: CGContext,
        chartRect: CGRect,
        minimum: Double,
        maximum: Double,
        step: Double
    ) {

        guard step > 0
        else {
            return
        }

        let range =
            maximum - minimum

        guard range > 0
        else {
            return
        }

        let firstTick =
            ceil(
                minimum / step
            ) * step

        var value =
            firstTick

        while value <= maximum + step * 0.001 {

            let ratio =
                (value - minimum) /
                range

            let y =
                chartRect.minY +
                CGFloat(ratio) *
                chartRect.height

            // -------------------------------------------------
            // 0 çizgisini burada çizme.
            // Ayrı olarak daha belirgin çizilecek.
            // -------------------------------------------------

            if abs(value) > step * 0.0001 {

                context.saveGState()

                context.setStrokeColor(
                    NSColor.separatorColor
                        .withAlphaComponent(0.45)
                        .cgColor
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
            }

            drawValueLabel(
                value: value,
                at: CGPoint(
                    x: chartRect.minX - 7,
                    y: y
                )
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

        let range =
            maximum - minimum

        guard range > 0
        else {
            return
        }

        // 0 ölçeğin dışındaysa çizme.
        guard minimum <= 0,
              maximum >= 0
        else {
            return
        }

        let zeroRatio =
            (0.0 - minimum) /
            range

        let zeroY =
            chartRect.minY +
            CGFloat(zeroRatio) *
            chartRect.height

        context.saveGState()

        context.setStrokeColor(
            zeroColor.withAlphaComponent(0.85).cgColor
        )

        context.setLineWidth(
            1.2
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

        // 0 etiketi.
        drawValueLabel(
            value: 0,
            at: CGPoint(
                x: chartRect.minX - 7,
                y: zeroY
            )
        )
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

        // Bar grubu biraz daha kompakt.
        let totalBarWidth =
            groupWidth * 0.76

        let barWidth =
            totalBarWidth /
            CGFloat(seriesCount)

        let range =
            maximum - minimum

        guard range > 0
        else {
            return
        }

        // -------------------------------------------------
        // Sıfırın grafik üzerindeki konumu.
        // -------------------------------------------------

        let zeroRatio =
            (0.0 - minimum) /
            range

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
                        minimum
                    ) /
                    range

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
                            ofSize: 8
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
                        21
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
                        ofSize: 8
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


