import Cocoa

final class RevenueCostChartRenderer {

    // MARK: - Data

    struct DataPoint {
        let revenue: Double
        let cost: Double

        var grossProfit: Double {
            revenue - cost
        }
    }

    // MARK: - Appearance

    private let revenueFillColor =
        NSColor.controlAccentColor.withAlphaComponent(0.12)

    private let revenueStrokeColor =
        NSColor.controlAccentColor.withAlphaComponent(0.75)

    private let costFillColor =
        NSColor.systemRed.withAlphaComponent(0.78)

    private let grossProfitFillColor =
        NSColor.systemGreen.withAlphaComponent(0.20)

    private let grossProfitStrokeColor =
        NSColor.systemGreen.withAlphaComponent(0.65)

    private let labelColor =
        NSColor.labelColor

    private let secondaryLabelColor =
        NSColor.secondaryLabelColor

    // MARK: - Layout

    private let barCornerRadius: CGFloat = 4

    private let valueLabelFont =
        NSFont.monospacedDigitSystemFont(
            ofSize: 12,
            weight: .medium
        )

    private let smallLabelFont =
        NSFont.systemFont(
            ofSize: 11,
            weight: .medium
        )

    // MARK: - Drawing

    /// Satış Gelirleri / Satışların Maliyeti / Brüt Kâr
    /// özel gösterimini çizer.
    ///
    /// Görsel mantık:
    ///
    ///     Satışların Maliyeti
    ///          ┌───────────┐
    ///          │███████████│
    ///          │███████████│
    ///          │███████████│
    ///          │███████████│
    ///          │           │
    ///          │  Brüt Kâr │
    ///          │           │
    ///          └───────────┘
    ///             ↑
    ///        Satış Gelirleri
    ///
    /// Gelir toplam sütunun tamamını oluşturur.
    /// Maliyet üstten aşağı doğru bu sütunu "ısırır".
    /// Geriye kalan bölüm brüt kârdır.
    func draw(
        data: [DataPoint],
        in chartRect: CGRect,
        barWidth: CGFloat,
        barSpacing: CGFloat,
        maximumValue: Double
    ) {

        guard !data.isEmpty else {
            return
        }

        guard maximumValue > 0 else {
            return
        }

        let totalWidth =
            CGFloat(data.count) * barWidth +
            CGFloat(max(0, data.count - 1)) * barSpacing

        let startX =
            chartRect.midX - totalWidth / 2.0

        for index in data.indices {

            let dataPoint = data[index]

            let x =
                startX +
                CGFloat(index) * (barWidth + barSpacing)

            let revenue = max(0, dataPoint.revenue)
            let cost = max(0, dataPoint.cost)
            let grossProfit = dataPoint.grossProfit

            let revenueHeight =
                CGFloat(revenue / maximumValue) *
                chartRect.height

            guard revenueHeight > 0 else {
                continue
            }

            let revenueRect = CGRect(
                x: x,
                y: chartRect.minY,
                width: barWidth,
                height: revenueHeight
            )

            drawRevenueColumn(
                rect: revenueRect
            )

            // -------------------------------------------------
            // Maliyet:
            // Gelir sütununun ÜSTÜNDEN aşağı doğru iner.
            // Böylece "gelirin ucundan ısırılmış" hissi verir.
            // -------------------------------------------------

            let costHeight =
                min(
                    revenueHeight,
                    CGFloat(cost / maximumValue) *
                    chartRect.height
                )

            let costRect = CGRect(
                x: x,
                y: revenueRect.maxY - costHeight,
                width: barWidth,
                height: costHeight
            )

            drawCostSection(
                rect: costRect
            )

            // -------------------------------------------------
            // Brüt kâr:
            // Maliyetin altında kalan bölüm.
            // -------------------------------------------------

            let grossProfitHeight =
                max(
                    0,
                    revenueHeight - costHeight
                )

            if grossProfitHeight > 0 {

                let grossProfitRect = CGRect(
                    x: x,
                    y: revenueRect.minY,
                    width: barWidth,
                    height: grossProfitHeight
                )

                drawGrossProfitSection(
                    rect: grossProfitRect
                )

                drawGrossProfitValue(
                    value: grossProfit,
                    rect: grossProfitRect
                )
            }

            // Maliyet değeri sütunun üstünde.
            drawCostValue(
                value: cost,
                rect: costRect
            )

            // Gelir değeri sütunun altında.
            drawRevenueValue(
                value: revenue,
                rect: revenueRect
            )
        }
    }

    // MARK: - Revenue

    private func drawRevenueColumn(
        rect: CGRect
    ) {

        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: barCornerRadius,
            yRadius: barCornerRadius
        )

        revenueFillColor.setFill()
        path.fill()

        revenueStrokeColor.setStroke()
        path.lineWidth = 1.2
        path.stroke()
    }

    // MARK: - Cost

    private func drawCostSection(
        rect: CGRect
    ) {

        guard rect.height > 0 else {
            return
        }

        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: barCornerRadius,
            yRadius: barCornerRadius
        )

        costFillColor.setFill()
        path.fill()

        // Maliyetin alt sınırını belirginleştiriyoruz.
        // Bu çizgi, maliyet ile brüt kâr arasındaki sınırı
        // görsel olarak netleştirir.
        if rect.height > 2 {

            let boundaryPath = NSBezierPath()

            boundaryPath.move(
                to: CGPoint(
                    x: rect.minX,
                    y: rect.minY
                )
            )

            boundaryPath.line(
                to: CGPoint(
                    x: rect.maxX,
                    y: rect.minY
                )
            )

            NSColor.systemRed
                .withAlphaComponent(0.95)
                .setStroke()

            boundaryPath.lineWidth = 1.5
            boundaryPath.stroke()
        }
    }

    // MARK: - Gross Profit

    private func drawGrossProfitSection(
        rect: CGRect
    ) {

        guard rect.height > 0 else {
            return
        }

        // Brüt kâr bölümünü ayrıca doldurmuyoruz.
        // Gelir sütununun arka planı görünmeye devam ediyor.
        //
        // Sadece alt bölümün sınırını hafifçe belirginleştiriyoruz.

        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: barCornerRadius,
            yRadius: barCornerRadius
        )

        grossProfitFillColor.setFill()
        path.fill()

        grossProfitStrokeColor.setStroke()
        path.lineWidth = 0.8
        path.stroke()
    }

    // MARK: - Value Labels

    private func drawCostValue(
        value: Double,
        rect: CGRect
    ) {

        let text = formatValue(value)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: valueLabelFont,
            .foregroundColor: labelColor
        ]

        let size =
            text.size(
                withAttributes: attributes
            )

        let x =
            rect.midX - size.width / 2.0

        let y =
            rect.maxY + 6

        text.draw(
            at: CGPoint(
                x: x,
                y: y
            ),
            withAttributes: attributes
        )
    }

    private func drawGrossProfitValue(
        value: Double,
        rect: CGRect
    ) {

        guard rect.height >= 24 else {
            return
        }

        let text = formatValue(value)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: smallLabelFont,
            .foregroundColor: labelColor
        ]

        let size =
            text.size(
                withAttributes: attributes
            )

        let x =
            rect.midX - size.width / 2.0

        let y =
            rect.midY - size.height / 2.0

        text.draw(
            at: CGPoint(
                x: x,
                y: y
            ),
            withAttributes: attributes
        )
    }

    private func drawRevenueValue(
        value: Double,
        rect: CGRect
    ) {

        let text = formatValue(value)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: smallLabelFont,
            .foregroundColor: secondaryLabelColor
        ]

        let size =
            text.size(
                withAttributes: attributes
            )

        let x =
            rect.midX - size.width / 2.0

        let y =
            rect.minY - size.height - 5

        text.draw(
            at: CGPoint(
                x: x,
                y: y
            ),
            withAttributes: attributes
        )
    }

    // MARK: - Formatting

    private func formatValue(
        _ value: Double
    ) -> String {

        let absoluteValue = abs(value)

        if absoluteValue >= 1_000_000_000 {

            return String(
                format: "%.2f B",
                value / 1_000_000_000
            )

        } else if absoluteValue >= 1_000_000 {

            return String(
                format: "%.2f M",
                value / 1_000_000
            )

        } else if absoluteValue >= 1_000 {

            return String(
                format: "%.1f K",
                value / 1_000
            )

        } else {

            return String(
                format: "%.0f",
                value
            )
        }
    }
}



