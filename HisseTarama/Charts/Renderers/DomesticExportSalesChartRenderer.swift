import Cocoa

final class DomesticExportSalesChartRenderer: NSView {

    // MARK: - Data

    private var domesticItem: FinancialStatementItem?
    private var exportItem: FinancialStatementItem?
    private var periods: [FinancialPeriod] = []
    private var isUSDMode = false

    // Hover yapılan sütunun index'i.
    private var hoveredPeriodIndex: Int?

    // MARK: - Layout

    private let outerMargin: CGFloat = 8
    private let leftMargin: CGFloat = 60
    private let rightMargin: CGFloat = 24
    private let topMargin: CGFloat = 58
    private let bottomMargin: CGFloat = 55

    // MARK: - Colors

    // Yurtiçi satışlar - kahverengi
    private let domesticColor =
        NSColor(
            calibratedRed: 0.55,
            green: 0.36,
            blue: 0.20,
            alpha: 1.0
        )

    // Yurtdışı satışlar - hardal
    private let exportColor =
        NSColor(
            calibratedRed: 0.78,
            green: 0.62,
            blue: 0.20,
            alpha: 1.0
        )

    private let gridColor =
        NSColor(
            calibratedWhite: 0.88,
            alpha: 1.0
        )

    private let axisColor =
        NSColor(
            calibratedWhite: 0.55,
            alpha: 1.0
        )

    private let borderColor =
        NSColor(
            calibratedWhite: 0.78,
            alpha: 1.0
        )

    // MARK: - Fonts

    private let periodFont =
        NSFont.systemFont(
            ofSize: 12,
            weight: .regular
        )

    private let axisFont =
        NSFont.systemFont(
            ofSize: 12,
            weight: .regular
        )

    private let legendFont =
        NSFont.systemFont(
            ofSize: 12,
            weight: .medium
        )

    private let hoverValueFont =
        NSFont.systemFont(
            ofSize: 12,
            weight: .medium
        )

    // MARK: - Mouse Tracking

    private var trackingArea: NSTrackingArea?

    // MARK: - Lifecycle

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
                .activeInKeyWindow
            ],
            owner: self,
            userInfo: nil
        )

        addTrackingArea(area)

        trackingArea = area
    }

    // MARK: - Public API

    func setData(
        domesticItem: FinancialStatementItem,
        exportItem: FinancialStatementItem,
        periods: [FinancialPeriod]
    ) {

        self.domesticItem = domesticItem
        self.exportItem = exportItem

        // Dönemleri kronolojik sıraya sokuyoruz.
        //
        // Genel grafik kuralımız:
        // soldan sağa -> eskiden yeniye
        //
        // Böylece en güncel çeyrek her zaman en sağda olur.

        self.periods = periods.sorted {

            if $0.year != $1.year {
                return $0.year < $1.year
            }

            return $0.quarter < $1.quarter
        }

        hoveredPeriodIndex = nil

        needsDisplay = true
    }

    func setCurrency(isUSD: Bool) {

        self.isUSDMode = isUSD

        needsDisplay = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {

        super.draw(dirtyRect)

        guard
            let domesticItem = domesticItem,
            let exportItem = exportItem,
            !periods.isEmpty
        else {

            drawEmptyState()

            return
        }

        let chartRect = bounds.insetBy(
            dx: outerMargin,
            dy: outerMargin
        )

        drawOuterBorder(
            in: chartRect
        )

        drawLegend(
            in: chartRect
        )

        let plottingRect = NSRect(
            x: chartRect.minX + leftMargin,
            y: chartRect.minY + bottomMargin,
            width: chartRect.width - leftMargin - rightMargin,
            height: chartRect.height - topMargin - bottomMargin
        )

        guard
            plottingRect.width > 0,
            plottingRect.height > 0
        else {
            return
        }

        let values = makeValues(
            domesticItem: domesticItem,
            exportItem: exportItem
        )

        let maxTotal = values
            .map { $0.domestic + $0.export }
            .max() ?? 0

        guard maxTotal > 0 else {

            drawEmptyState(
                in: plottingRect
            )

            return
        }

        drawGrid(
            in: plottingRect,
            maximumValue: maxTotal
        )

        drawBars(
            values: values,
            in: plottingRect,
            maximumValue: maxTotal
        )

        drawYAxis(
            in: plottingRect,
            maximumValue: maxTotal
        )

        drawPeriodLabels(
            in: plottingRect
        )

        // Hover bilgileri en son çiziliyor.
        //
        // Böylece yazılar sütunların ve diğer grafik
        // elemanlarının üzerinde kalıyor.

        drawHoverValues(
            values: values,
            in: plottingRect,
            maximumValue: maxTotal
        )
    }

    // MARK: - Values

    private struct DataPoint {

        let period: FinancialPeriod
        let domestic: Double
        let export: Double

        var total: Double {
            domestic + export
        }

        var domesticPercentage: Double {

            guard total > 0 else {
                return 0
            }

            return domestic / total * 100
        }

        var exportPercentage: Double {

            guard total > 0 else {
                return 0
            }

            return export / total * 100
        }
    }

    private func makeValues(
        domesticItem: FinancialStatementItem,
        exportItem: FinancialStatementItem
    ) -> [DataPoint] {

        periods.map { period in

            let domestic =
                domesticItem.value(
                    for: period
                ) ?? 0

            let export =
                exportItem.value(
                    for: period
                ) ?? 0

            return DataPoint(
                period: period,
                domestic: domestic,
                export: export
            )
        }
    }

    // MARK: - Outer Border

    private func drawOuterBorder(
        in rect: NSRect
    ) {

        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: 8,
            yRadius: 8
        )

        borderColor.setStroke()

        path.lineWidth = 1

        path.stroke()
    }

    // MARK: - Legend

    private func drawLegend(
        in rect: NSRect
    ) {

        let domesticText =
            "Yurtiçi Satışlar"

        let exportText =
            "Yurtdışı Satışlar"

        let domesticAttributes:
            [NSAttributedString.Key: Any] = [
                .font: legendFont,
                .foregroundColor: NSColor.labelColor
            ]

        let domesticSize =
            (domesticText as NSString).size(
                withAttributes: domesticAttributes
            )

        let exportSize =
            (exportText as NSString).size(
                withAttributes: domesticAttributes
            )

        let squareSize: CGFloat = 10
        let squareGap: CGFloat = 5
        let textGap: CGFloat = 7

        let totalWidth =
            squareSize
            + squareGap
            + domesticSize.width
            + textGap
            + exportSize.width
            + squareGap
            + squareSize

        let startX =
            rect.midX - totalWidth / 2

        let centerY =
            rect.maxY - 28

        // Sol kare - Yurtiçi

        let domesticSquare = NSRect(
            x: startX,
            y: centerY - squareSize / 2,
            width: squareSize,
            height: squareSize
        )

        domesticColor.setFill()

        NSBezierPath(
            rect: domesticSquare
        ).fill()

        // Yurtiçi text

        let domesticTextX =
            domesticSquare.maxX + squareGap

        let domesticTextY =
            centerY - domesticSize.height / 2

        domesticText.draw(
            at: NSPoint(
                x: domesticTextX,
                y: domesticTextY
            ),
            withAttributes: domesticAttributes
        )

        // Yurtdışı text

        let exportTextX =
            domesticTextX
            + domesticSize.width
            + textGap

        let exportTextY =
            centerY - exportSize.height / 2

        exportText.draw(
            at: NSPoint(
                x: exportTextX,
                y: exportTextY
            ),
            withAttributes: domesticAttributes
        )

        // Sağ kare - Yurtdışı

        let exportSquare = NSRect(
            x: exportTextX + exportSize.width + squareGap,
            y: centerY - squareSize / 2,
            width: squareSize,
            height: squareSize
        )

        exportColor.setFill()

        NSBezierPath(
            rect: exportSquare
        ).fill()
    }

    // MARK: - Grid

    private func drawGrid(
        in rect: NSRect,
        maximumValue: Double
    ) {

        let gridCount = 4

        gridColor.setStroke()

        for index in 0...gridCount {

            let ratio =
                CGFloat(index) /
                CGFloat(gridCount)

            let y =
                rect.minY +
                rect.height * ratio

            let path = NSBezierPath()

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

            path.lineWidth = 0.5

            path.stroke()
        }
    }

    // MARK: - Y Axis

    private func drawYAxis(
        in rect: NSRect,
        maximumValue: Double
    ) {

        let gridCount = 4

        let attributes:
            [NSAttributedString.Key: Any] = [
                .font: axisFont,
                .foregroundColor:
                    NSColor.secondaryLabelColor
            ]

        for index in 0...gridCount {

            let ratio =
                Double(index) /
                Double(gridCount)

            let value =
                maximumValue * ratio

            let y =
                rect.minY +
                rect.height * CGFloat(ratio)

            let text =
                formatAxisValue(value)

            let size =
                (text as NSString).size(
                    withAttributes: attributes
                )

            text.draw(
                at: NSPoint(
                    x:
                        rect.minX -
                        size.width -
                        8,
                    y:
                        y -
                        size.height / 2
                ),
                withAttributes: attributes
            )
        }

        axisColor.setStroke()

        let axisPath = NSBezierPath()

        axisPath.move(
            to: NSPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        axisPath.line(
            to: NSPoint(
                x: rect.minX,
                y: rect.maxY
            )
        )

        axisPath.lineWidth = 0.7

        axisPath.stroke()
    }

    // MARK: - Bars

    private func drawBars(
        values: [DataPoint],
        in rect: NSRect,
        maximumValue: Double
    ) {

        guard !values.isEmpty else {
            return
        }

        let count = values.count

        let slotWidth =
            rect.width /
            CGFloat(count)

        let barWidth =
            min(
                slotWidth * 0.56,
                54
            )

        for index in values.indices {

            let point = values[index]

            let centerX =
                rect.minX +
                slotWidth *
                (CGFloat(index) + 0.5)

            let barX =
                centerX -
                barWidth / 2

            let domesticHeight =
                CGFloat(
                    point.domestic /
                    maximumValue
                ) *
                rect.height

            let exportHeight =
                CGFloat(
                    point.export /
                    maximumValue
                ) *
                rect.height

            let domesticRect = NSRect(
                x: barX,
                y: rect.minY,
                width: barWidth,
                height: domesticHeight
            )

            let exportRect = NSRect(
                x: barX,
                y: rect.minY + domesticHeight,
                width: barWidth,
                height: exportHeight
            )

            let isHighlighted =
                isPeriodHighlighted(index)

            let alpha =
            isHighlighted ? 0.85 : 0.15

            domesticColor
                .withAlphaComponent(alpha)
                .setFill()

            if domesticHeight > 0 {

                NSBezierPath(
                    rect: domesticRect
                ).fill()
            }

            exportColor
                .withAlphaComponent(alpha)
                .setFill()

            if exportHeight > 0 {

                drawExportSegment(
                    rect: exportRect
                )
            }

            // Hover korunuyor.
            // Sadece sütun etrafındaki ekstra border kaldırıldı.
        }
    }

    // MARK: - Export Segment

    private func drawExportSegment(
        rect: NSRect
    ) {

        guard rect.height > 0 else {
            return
        }

        NSBezierPath(
            rect: rect
        ).fill()
    }

    // MARK: - Period Labels

    private func drawPeriodLabels(
        in rect: NSRect
    ) {

        guard !periods.isEmpty else {
            return
        }

        let count = periods.count

        let slotWidth =
            rect.width /
            CGFloat(count)

        let attributes:
            [NSAttributedString.Key: Any] = [
                .font: periodFont,
                .foregroundColor:
                    NSColor.secondaryLabelColor
            ]

        for index in periods.indices {

            let period = periods[index]

            let text =
                periodLabel(
                    for: period
                )

            let size =
                (text as NSString).size(
                    withAttributes: attributes
                )

            let centerX =
                rect.minX +
                slotWidth *
                (CGFloat(index) + 0.5)

            let alpha =
                isPeriodHighlighted(index)
                ? 1.0
                : 0.25

            let labelAttributes:
                [NSAttributedString.Key: Any] = [
                    .font: periodFont,
                    .foregroundColor:
                        NSColor.secondaryLabelColor
                        .withAlphaComponent(alpha)
                ]

            text.draw(
                at: NSPoint(
                    x:
                        centerX -
                        size.width / 2,
                    y:
                        rect.minY -
                        size.height -
                        8
                ),
                withAttributes:
                    labelAttributes
            )
        }
    }

    // MARK: - Hover Values

    private func drawHoverValues(
        values: [DataPoint],
        in rect: NSRect,
        maximumValue: Double
    ) {

        guard
            let hoveredPeriodIndex =
                hoveredPeriodIndex
        else {
            return
        }

        guard
            hoveredPeriodIndex >= 0,
            hoveredPeriodIndex < values.count
        else {
            return
        }

        let hoveredQuarter =
            values[
                hoveredPeriodIndex
            ].period.quarter

        let count = values.count

        let slotWidth =
            rect.width /
            CGFloat(count)

        let barWidth =
            min(
                slotWidth * 0.56,
                54
            )

        for index in values.indices {

            guard
                values[index].period.quarter
                    ==
                hoveredQuarter
            else {
                continue
            }

            let point =
                values[index]

            let centerX =
                rect.minX +
                slotWidth *
                (CGFloat(index) + 0.5)

            let domesticHeight =
                CGFloat(
                    point.domestic /
                    maximumValue
                ) *
                rect.height

            let exportHeight =
                CGFloat(
                    point.export /
                    maximumValue
                ) *
                rect.height

            let barTop =
                rect.minY +
                domesticHeight +
                exportHeight

            drawHoverInformation(
                for: point,
                centerX: centerX,
                barWidth: barWidth,
                barTop: barTop,
                chartRect: rect
            )
        }
    }

    private func drawHoverInformation(
        for point: DataPoint,
        centerX: CGFloat,
        barWidth: CGFloat,
        barTop: CGFloat,
        chartRect: NSRect
    ) {

        let domesticText =
            "Y.içi  \(formatValue(point.domestic))  \(formatPercentage(point.domesticPercentage))"

        let exportText =
            "Y.dışı  \(formatValue(point.export))  \(formatPercentage(point.exportPercentage))"

        let domesticAttributes:
            [NSAttributedString.Key: Any] = [
                .font: hoverValueFont,
                .foregroundColor: domesticColor
            ]

        let exportAttributes:
            [NSAttributedString.Key: Any] = [
                .font: hoverValueFont,
                .foregroundColor: exportColor
            ]

        let domesticSize =
            (domesticText as NSString).size(
                withAttributes:
                    domesticAttributes
            )

        let exportSize =
            (exportText as NSString).size(
                withAttributes:
                    exportAttributes
            )

        let maxTextWidth =
            max(
                domesticSize.width,
                exportSize.width
            )

        let lineHeight: CGFloat = 13

        let totalHeight =
            lineHeight * 2

        var firstLineY =
            barTop + 6

        let maximumTop =
            chartRect.maxY -
            totalHeight -
            2

        if firstLineY > maximumTop {
            firstLineY = maximumTop
        }

        let centerTextX =
            centerX -
            maxTextWidth / 2

        domesticText.draw(
            at: NSPoint(
                x: centerTextX,
                y: firstLineY + lineHeight
            ),
            withAttributes:
                domesticAttributes
        )

        exportText.draw(
            at: NSPoint(
                x: centerTextX,
                y: firstLineY
            ),
            withAttributes:
                exportAttributes
        )
    }

    // MARK: - Hover Highlight

    private func isPeriodHighlighted(
        _ index: Int
    ) -> Bool {

        guard
            let hoveredPeriodIndex =
                hoveredPeriodIndex
        else {
            return true
        }

        guard
            hoveredPeriodIndex >= 0,
            hoveredPeriodIndex < periods.count,
            index >= 0,
            index < periods.count
        else {
            return false
        }

        return periods[index].quarter
            ==
            periods[hoveredPeriodIndex].quarter
    }

    // MARK: - Mouse

    override func mouseMoved(
        with event: NSEvent
    ) {

        guard !periods.isEmpty else {
            return
        }

        let location =
            convert(
                event.locationInWindow,
                from: nil
            )

        let chartRect =
            bounds.insetBy(
                dx: outerMargin,
                dy: outerMargin
            )

        let plottingRect = NSRect(
            x:
                chartRect.minX +
                leftMargin,
            y:
                chartRect.minY +
                bottomMargin,
            width:
                chartRect.width -
                leftMargin -
                rightMargin,
            height:
                chartRect.height -
                topMargin -
                bottomMargin
        )

        guard plottingRect.contains(location) else {

            if hoveredPeriodIndex != nil {

                hoveredPeriodIndex = nil

                needsDisplay = true
            }

            return
        }

        let count = periods.count

        let slotWidth =
            plottingRect.width /
            CGFloat(count)

        let relativeX =
            location.x -
            plottingRect.minX

        var index =
            Int(
                relativeX /
                slotWidth
            )

        index =
            max(
                0,
                min(
                    count - 1,
                    index
                )
            )

        if hoveredPeriodIndex != index {

            hoveredPeriodIndex = index

            needsDisplay = true
        }
    }

    override func mouseExited(
        with event: NSEvent
    ) {

        if hoveredPeriodIndex != nil {

            hoveredPeriodIndex = nil

            needsDisplay = true
        }
    }

    // MARK: - Empty State

    private func drawEmptyState() {

        let text =
            "Veri bulunamadı"

        let attributes:
            [NSAttributedString.Key: Any] = [
                .font:
                    NSFont.systemFont(
                        ofSize: 12,
                        weight: .regular
                    ),
                .foregroundColor:
                    NSColor.secondaryLabelColor
            ]

        let size =
            (text as NSString).size(
                withAttributes:
                    attributes
            )

        text.draw(
            at: NSPoint(
                x:
                    bounds.midX -
                    size.width / 2,
                y:
                    bounds.midY -
                    size.height / 2
            ),
            withAttributes:
                attributes
        )
    }

    private func drawEmptyState(
        in rect: NSRect
    ) {

        let text =
            "Veri bulunamadı"

        let attributes:
            [NSAttributedString.Key: Any] = [
                .font:
                    NSFont.systemFont(
                        ofSize: 11,
                        weight: .regular
                    ),
                .foregroundColor:
                    NSColor.secondaryLabelColor
            ]

        let size =
            (text as NSString).size(
                withAttributes:
                    attributes
            )

        text.draw(
            at: NSPoint(
                x:
                    rect.midX -
                    size.width / 2,
                y:
                    rect.midY -
                    size.height / 2
            ),
            withAttributes:
                attributes
        )
    }

    // MARK: - Formatting

    private func formatValue(
        _ value: Double
    ) -> String {

        let absoluteValue =
            abs(value)

        let sign =
            value < 0 ? "-" : ""

        if absoluteValue >= 1_000_000_000 {

            let formatted =
                absoluteValue /
                1_000_000_000

            return
                "\(sign)\(formatDecimal(formatted)) Mly"
        }

        if absoluteValue >= 1_000_000 {

            let formatted =
                absoluteValue /
                1_000_000

            return
                "\(sign)\(formatDecimal(formatted)) M"
        }

        if absoluteValue >= 1_000 {

            let formatted =
                absoluteValue /
                1_000

            return
                "\(sign)\(formatDecimal(formatted)) B"
        }

        return
            "\(sign)\(formatDecimal(absoluteValue))"
    }

    private func formatAxisValue(
        _ value: Double
    ) -> String {

        let absoluteValue =
            abs(value)

        if absoluteValue >= 1_000_000_000 {

            return
                "\(formatDecimal(value / 1_000_000_000)) Mly"
        }

        if absoluteValue >= 1_000_000 {

            return
                "\(formatDecimal(value / 1_000_000)) M"
        }

        if absoluteValue >= 1_000 {

            return
                "\(formatDecimal(value / 1_000)) B"
        }

        return formatDecimal(value)
    }

    private func formatPercentage(
        _ value: Double
    ) -> String {

        return
            "\(formatDecimal(value))%"
    }

    private func formatDecimal(
        _ value: Double
    ) -> String {

        let formatter =
            NumberFormatter()

        formatter.numberStyle =
            .decimal

        formatter.locale =
            Locale(
                identifier: "tr_TR"
            )

        formatter.minimumFractionDigits =
            0

        formatter.maximumFractionDigits =
            1

        return
            formatter.string(
                from:
                    NSNumber(
                        value: value
                    )
            )
            ?? "\(value)"
    }

    private func periodLabel(
        for period: FinancialPeriod
    ) -> String {

        return
            "\(period.year) Q\(period.quarter)"
    }
}
