
import Cocoa

final class FundamentalChartViewController: NSViewController {

    // MARK: - Data

    private var items: [FinancialStatementItem] = []
    private var periods: [FinancialPeriod] = []

    // MARK: - UI

    private let titleLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "Finansal Grafik"
        )

        label.font = NSFont.systemFont(
            ofSize: 18,
            weight: .semibold
        )

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let subtitleLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: ""
        )

        label.font = NSFont.systemFont(
            ofSize: 12
        )

        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let chartView: FundamentalBarChartView = {
        let chart = FundamentalBarChartView()

        chart.translatesAutoresizingMaskIntoConstraints = false

        return chart
    }()

    private let emptyStateLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "Görüntülenecek finansal veri yok."
        )

        label.alignment = .center

        label.font = NSFont.systemFont(
            ofSize: 15
        )

        label.textColor = .secondaryLabelColor

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Lifecycle

    override func loadView() {

        view = NSView()
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setupView()

        updateEmptyState()
    }

    // MARK: - Setup

    private func setupView() {

        view.wantsLayer = true

        view.addSubview(
            titleLabel
        )

        view.addSubview(
            subtitleLabel
        )

        view.addSubview(
            chartView
        )

        view.addSubview(
            emptyStateLabel
        )

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 16
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),

            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -20
            ),

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 4
            ),

            subtitleLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            subtitleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -20
            ),

            chartView.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor,
                constant: 16
            ),

            chartView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),

            chartView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),

            chartView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -20
            ),

            emptyStateLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            emptyStateLabel.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),

            emptyStateLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 20
            ),

            emptyStateLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -20
            )
        ])
    }

    // MARK: - Public API

    func show(
        items: [FinancialStatementItem],
        periods: [FinancialPeriod]
    ) {

        self.items = items
        self.periods = periods

        updateChart()
    }

    func clearChart() {

        items.removeAll()
        periods.removeAll()

        titleLabel.stringValue =
            "Finansal Grafik"

        subtitleLabel.stringValue =
            ""

        chartView.setData(
            items: [],
            periods: []
        )

        updateEmptyState()
    }

    // MARK: - Update

    private func updateChart() {

        guard !items.isEmpty,
              !periods.isEmpty
        else {

            clearChart()

            return
        }

        updateTitle()

        updateSubtitle()

        chartView.setData(
            items: items,
            periods: periods
        )

        updateEmptyState()
    }

    private func updateTitle() {

        if items.count == 1 {

            titleLabel.stringValue =
                items[0].name

        } else {

            titleLabel.stringValue =
                "Finansal Karşılaştırma"
        }
    }

    private func updateSubtitle() {

        if items.count == 1 {

            subtitleLabel.stringValue =
                "\(items[0].itemCode) • \(periods.count) dönem"

        } else {

            let names =
                items
                    .map {
                        $0.name
                    }
                    .joined(
                        separator: " + "
                    )

            subtitleLabel.stringValue =
                "\(names) • \(periods.count) dönem"
        }
    }

    private func updateEmptyState() {

        let hasData =
            !items.isEmpty &&
            !periods.isEmpty

        chartView.isHidden =
            !hasData

        emptyStateLabel.isHidden =
            hasData
    }
}


// MARK: - Bar Chart View

final class FundamentalBarChartView: NSView {

    // MARK: - Data

    private var items:
        [FinancialStatementItem] = []

    private var periods:
        [FinancialPeriod] = []

    // MARK: - Layout

    private let leftMargin: CGFloat = 80

    private let rightMargin: CGFloat = 20

    private let topMargin: CGFloat = 20

    private let bottomMargin: CGFloat = 55

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

        self.periods = periods

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

        let values =
            allValues()

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
            NSColor.secondaryLabelColor.cgColor
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

        let periodCount = periods.count

        guard periodCount > 0 else {
            return
        }

        let seriesCount = max(
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

        // Güvenli Double değerleri
        let minValue: Double = minimum
        let maxValue: Double = maximum

        let calculatedRange: Double =
            maxValue - minValue

        let safeRange: Double =
            calculatedRange == 0.0
            ? 1.0
            : calculatedRange

        // Sıfırın grafik üzerindeki konumu
        let zeroRatio: Double =
            (0.0 - minValue) /
            safeRange

        let zeroY: CGFloat =
            chartRect.minY +
            CGFloat(zeroRatio) *
            chartRect.height

        // Her dönem
        for periodIndex in 0..<periodCount {

            let period =
                periods[periodIndex]

            // Her finansal kalem
            for itemIndex in 0..<items.count {

                let item =
                    items[itemIndex]

                // Dictionary lookup sonucu Double??
                guard let optionalValue =
                    item.values[period]
                else {
                    continue
                }

                // Double?? -> Double?
                guard let value =
                    optionalValue
                else {
                    continue
                }

                // Double? problemi burada tamamen bitiyor.
                let numericValue: Double =
                    value

                let valueRatio: Double =
                    (
                        numericValue -
                        minValue
                    ) /
                    safeRange

                let valueY: CGFloat =
                    chartRect.minY +
                    CGFloat(valueRatio) *
                    chartRect.height

                let x: CGFloat =
                    chartRect.minX +
                    CGFloat(periodIndex) *
                    groupWidth +
                    (
                        groupWidth -
                        totalBarWidth
                    ) / 2.0 +
                    CGFloat(itemIndex) *
                    barWidth

                let y: CGFloat =
                    min(
                        zeroY,
                        valueY
                    )

                let height: CGFloat =
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
                        index: itemIndex
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
        index: Int
    ) -> NSColor {

        let colors: [NSColor] = [

            NSColor.systemBlue,

            NSColor.systemOrange,

            NSColor.systemGreen,

            NSColor.systemRed,

            NSColor.systemPurple,

            NSColor.systemYellow
        ]

        return colors[
            index %
            colors.count
        ]
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
