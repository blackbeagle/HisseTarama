// CandlestickChartView.swift
import Cocoa

class CandlestickChartView: NSView {
    
    // MARK: - Properties
    var candlesticks: [Candlestick] = [] {
        didSet {
            needsDisplay = true
        }
    }
    
    // Grafik kenar boşlukları
    private let leftMargin: CGFloat = 55
    private let rightMargin: CGFloat = 35
    private let topMargin: CGFloat = 35
    private let bottomMargin: CGFloat = 45
    
    // Fare takibi için
    private var trackingArea: NSTrackingArea?
    private var highlightedIndex: Int?
    
    private var mouseLocation: NSPoint?
    
    
    var activeSMAs: [Int: [Double?]] = [:]
    
    
    // Görüntülenecek bar sayısı
    var visibleBarCount = 150

    // İlk gösterilen barın index'i
    private var firstVisibleBar = 0

    // Fare sürükleme
    private var lastDragPoint: NSPoint?
    
    // MARK: - Initialization
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        autoresizingMask = [.width, .height]
    }
    
    // MARK: - Mouse Tracking
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
    /*
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        updateHighlightedIndex(at: location)
        needsDisplay = true
    }
    */
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        mouseLocation = location
        updateHighlightedIndex(at: location)

        needsDisplay = true
    }
    /*
    override func mouseExited(with event: NSEvent) {
        highlightedIndex = nil
        needsDisplay = true
    }
    */
    override func mouseExited(with event: NSEvent) {
        highlightedIndex = nil
        mouseLocation = nil
        needsDisplay = true
    }
    
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        
        if let index = getIndexAtPoint(location) {
            showDetailForCandlestick(at: index)
        }
    }
    
    private func updateHighlightedIndex(at point: NSPoint) {
        guard !candlesticks.isEmpty else {
            highlightedIndex = nil
            return
        }
        
        let chartRect = getChartRect()
        
        guard chartRect.contains(point) else {
            highlightedIndex = nil
            return
        }
        
        let xScale = chartRect.width / CGFloat(candlesticks.count - 1)
        let index = Int((point.x - chartRect.minX) / xScale)
        
        if index >= 0 && index < candlesticks.count {
            highlightedIndex = index
        } else {
            highlightedIndex = nil
        }
    }
    
    private func getIndexAtPoint(_ point: NSPoint) -> Int? {
        guard !candlesticks.isEmpty else { return nil }
        
        let chartRect = getChartRect()
        
        guard chartRect.contains(point) else { return nil }
        
        let xScale = chartRect.width / CGFloat(candlesticks.count - 1)
        let index = Int((point.x - chartRect.minX) / xScale)
        
        return (index >= 0 && index < candlesticks.count) ? index : nil
    }
    
    private func showDetailForCandlestick(at index: Int) {
        let stick = candlesticks[index]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        dateFormatter.locale = Locale(identifier: "tr_TR")
        
        let message = """
        📅 Tarih: \(dateFormatter.string(from: stick.date))
        📈 Max: \(String(format: "%.2f", stick.max))
        📉 Min: \(String(format: "%.2f", stick.min))
        📊 Aof: \(String(format: "%.2f", stick.weightedAverage))
        """
        
        let alert = NSAlert()
        alert.messageText = "Mum Detayı"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Tamam")
        alert.runModal()
    }
    
    private func getChartRect() -> NSRect {
        return NSRect(
            x: leftMargin,
            y: bottomMargin,
            width: bounds.width - leftMargin - rightMargin,
            height: bounds.height - topMargin - bottomMargin
        )
    }
    
    // MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        // Arkaplanı temizle
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setFillColor(NSColor.controlBackgroundColor.cgColor)
        context.fill(dirtyRect)
        
        guard !candlesticks.isEmpty else {
            drawEmptyState()
            return
        }
        
        // Fiyat aralığını bul
        let allMax = candlesticks.map { $0.max }.max() ?? 0
        let allMin = candlesticks.map { $0.min }.min() ?? 0
        let priceRange = allMax - allMin
        
        // Eğer fiyat aralığı çok küçükse (tüm fiyatlar aynı), bir miktar padding ekle
        let padding = priceRange == 0 ? 10 : priceRange * 0.05
        let yMax = allMax + padding
        let yMin = allMin - padding
        
        // Çizim alanı
        let chartRect = getChartRect()
        
        // Eğer çizim alanı geçersizse çizme
        guard chartRect.width > 0, chartRect.height > 0 else { return }
        
        // Y ekseni (fiyat) skalasını hesapla
        let yScale = chartRect.height / CGFloat(yMax - yMin)
        
        // X ekseni (zaman) skalası
        let xScale = chartRect.width / CGFloat(candlesticks.count - 1)
        
        // Arkaplan ızgarasını çiz
        drawGrid(chartRect: chartRect, yMin: yMin, yMax: yMax, yScale: yScale)
        
        // Her bir mum için çizim yap
        for (index, stick) in candlesticks.enumerated() {
            let x = chartRect.minX + CGFloat(index) * xScale
            let yMinPrice = CGFloat(stick.min - yMin) * yScale + chartRect.minY
            let yMaxPrice = CGFloat(stick.max - yMin) * yScale + chartRect.minY
            let yWeightedAvg = CGFloat(stick.weightedAverage - yMin) * yScale + chartRect.minY
            
            // Mum rengini belirle (önceki güne göre)
            let previousAvg = index > 0 ? candlesticks[index-1].weightedAverage : stick.weightedAverage
            let isRising = stick.weightedAverage >= previousAvg
            
            // Mum çubuğu (max-min arası çizgi)
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: x, y: yMinPrice))
            linePath.line(to: NSPoint(x: x, y: yMaxPrice))
            linePath.lineWidth = 1
            
            // Mum rengini ayarla
            if isRising {
                NSColor.systemGreen.setStroke()
            } else {
                NSColor.systemRed.setStroke()
            }
            linePath.stroke()
            
            // Ağırlıklı ortalama için yatay kısa çizgi
            let avgLinePath = NSBezierPath()
            let lineLength: CGFloat = 8.0
            avgLinePath.move(to: NSPoint(x: x - lineLength/2, y: yWeightedAvg))
            avgLinePath.line(to: NSPoint(x: x + lineLength/2, y: yWeightedAvg))
            avgLinePath.lineWidth = 1.2
            
            if isRising {
                NSColor.systemGreen.withAlphaComponent(0.9).setStroke()
            } else {
                NSColor.systemRed.withAlphaComponent(0.9).setStroke()
            }
            avgLinePath.stroke()
        }
        
        // Highlight varsa göster
        if let highlightedIndex = highlightedIndex {
            drawHighlight(for: highlightedIndex, chartRect: chartRect, yMin: yMin, yMax: yMax, yScale: yScale, xScale: xScale)
        }
        
        //drawMouseCrosshair(chartRect: chartRect)
        drawMouseCrosshair(
            chartRect: chartRect,
            yMin: yMin,
            yMax: yMax,
            xScale: xScale
        )
        drawSMAs(chartRect: chartRect, yMin: yMin, yMax: yMax, yScale: yScale, xScale: xScale)
        
        // Eksen etiketlerini çiz
        drawAxisLabels(chartRect: chartRect, yMin: yMin, yMax: yMax)
        
        // Grafik başlığını çiz
        drawChartTitle()
    }
    
    // MARK: - Drawing Helpers
    private func drawEmptyState() {
        let emptyText = "📊 Veri bulunmuyor\n\nHisse kodu girip 'Veri Getir' butonuna tıklayın" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: NSParagraphStyle.default
        ]
        
        let textSize = emptyText.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        emptyText.draw(in: textRect, withAttributes: attributes)
    }
    
    private func drawGrid(chartRect: NSRect, yMin: Double, yMax: Double, yScale: CGFloat) {
        NSColor.separatorColor.withAlphaComponent(0.3).setStroke()
        
        // Yatay çizgiler (5 adet)
        let gridLineCount = 5
        for i in 0...gridLineCount {
            let yValue = yMin + (yMax - yMin) * Double(i) / Double(gridLineCount)
            let y = CGFloat(yValue - yMin) * yScale + chartRect.minY
            
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: chartRect.minX, y: y))
            linePath.line(to: NSPoint(x: chartRect.maxX, y: y))
            linePath.lineWidth = 0.5
            linePath.stroke()
        }
        
        // Dikey çizgiler (her 10 mumda bir veya minimum 5 çizgi)
        let verticalLineCount = min(10, candlesticks.count)
        let step = max(1, candlesticks.count / verticalLineCount)
        
        for i in stride(from: 0, to: candlesticks.count, by: step) {
            let x = chartRect.minX + CGFloat(i) * (chartRect.width / CGFloat(candlesticks.count - 1))
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: x, y: chartRect.minY))
            linePath.line(to: NSPoint(x: x, y: chartRect.maxY))
            linePath.lineWidth = 0.5
            linePath.stroke()
        }
    }
    private func colorForSMA(period: Int) -> NSColor {

        switch period {

        case 8:
            return .systemGreen

        case 34:
            return .systemBlue

        case 52:
            return .black

        default:
            return .systemOrange
        }
    }
    private func drawSMAs(chartRect: NSRect, yMin: Double, yMax: Double, yScale: CGFloat, xScale: CGFloat) {
        guard !activeSMAs.isEmpty else { return }
        
        //let colors: [NSColor] = [.systemBlue, .systemPurple, .systemOrange, .systemBrown, .systemTeal]
        //var colorIndex = 0
        
        for (period, smaValues) in activeSMAs.sorted(by: { $0.key < $1.key }) {
            guard smaValues.count == candlesticks.count else { continue }
            
           // let color = colors[colorIndex % colors.count]
            let color = colorForSMA(period: period)
            
            color.setStroke()
            
            let path = NSBezierPath()
            var isFirstPoint = true
            
            for (index, smaValue) in smaValues.enumerated() {
                guard let value = smaValue else { continue }
                
                let x = chartRect.minX + CGFloat(index) * xScale
                let y = CGFloat(value - yMin) * yScale + chartRect.minY
                
                if isFirstPoint {
                    path.move(to: NSPoint(x: x, y: y))
                    isFirstPoint = false
                } else {
                    path.line(to: NSPoint(x: x, y: y))
                }
            }
            
            path.lineWidth = 0.75
            path.stroke()
            
            //colorIndex += 1
        }
    }
    
    private func drawHighlight(for index: Int, chartRect: NSRect, yMin: Double, yMax: Double, yScale: CGFloat, xScale: CGFloat) {
        let stick = candlesticks[index]
        let x = chartRect.minX + CGFloat(index) * xScale
        let yMaxPrice = CGFloat(stick.max - yMin) * yScale + chartRect.minY
        let yMinPrice = CGFloat(stick.min - yMin) * yScale + chartRect.minY
        
        // Highlight arkaplanı (yuvarlak veya dikdörtgen)
        let highlightRect = NSRect(x: x - 12, y: yMinPrice - 5, width: 24, height: yMaxPrice - yMinPrice + 10)
        let highlightPath = NSBezierPath(roundedRect: highlightRect, xRadius: 4, yRadius: 4)
        NSColor.systemYellow.withAlphaComponent(0.3).setFill()
        highlightPath.fill()
        
        // Tooltip benzeri bilgi
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        
        let infoText = """
        📅 \(dateFormatter.string(from: stick.date))
        ↑ \(String(format: "%.2f", stick.max))
        ↓ \(String(format: "%.2f", stick.min))
        ⚖️ \(String(format: "%.2f", stick.weightedAverage))
        """
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.windowBackgroundColor.withAlphaComponent(0.9)
        ]
        
        // Tooltip pozisyonunu belirle (saga veya sola kaydır)
        var tooltipX = x + 15
        if tooltipX + 80 > chartRect.maxX {
            tooltipX = x - 95
        }
        
        let textRect = NSRect(x: tooltipX, y: yMaxPrice + 5, width: 85, height: 70)
        (infoText as NSString).draw(in: textRect, withAttributes: attributes)
    }
    
    private func drawAxisLabels(chartRect: NSRect, yMin: Double, yMax: Double) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        // Y ekseni etiketleri (fiyatlar)
        let labelCount = 5
        for i in 0...labelCount {
            let yValue = yMin + (yMax - yMin) * Double(i) / Double(labelCount)
            let y = chartRect.minY + CGFloat(i) * (chartRect.height / CGFloat(labelCount))
            let label = String(format: "%.2f", yValue) as NSString
            label.draw(at: NSPoint(x: 8, y: y - 7), withAttributes: attributes)
        }
        
        // X ekseni etiketleri (tarihler)
        if candlesticks.count > 1,
           let firstDate = candlesticks.first?.date,
           let lastDate = candlesticks.last?.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM"
            dateFormatter.locale = Locale(identifier: "tr_TR")
            
            let firstLabel = dateFormatter.string(from: firstDate) as NSString
            let lastLabel = dateFormatter.string(from: lastDate) as NSString
            
            let firstLabelSize = firstLabel.size(withAttributes: attributes)
            let lastLabelSize = lastLabel.size(withAttributes: attributes)
            
            firstLabel.draw(at: NSPoint(x: chartRect.minX - 5, y: bounds.height - bottomMargin + 8), withAttributes: attributes)
            lastLabel.draw(at: NSPoint(x: chartRect.maxX - lastLabelSize.width + 5, y: bounds.height - bottomMargin + 8), withAttributes: attributes)
            
            // Ortadaki bir tarihi de göster
            let middleIndex = candlesticks.count / 2
            if middleIndex > 0 && middleIndex < candlesticks.count - 1 {
                let middleDate = candlesticks[middleIndex].date
                let middleLabel = dateFormatter.string(from: middleDate) as NSString
                let middleX = chartRect.minX + CGFloat(middleIndex) * (chartRect.width / CGFloat(candlesticks.count - 1))
                let middleLabelSize = middleLabel.size(withAttributes: attributes)
                middleLabel.draw(at: NSPoint(x: middleX - middleLabelSize.width / 2, y: bounds.height - bottomMargin + 8), withAttributes: attributes)
            }
        }
        
        // Y ekseni etiketi
        let yAxisLabel = "Fiyat (₺)" as NSString
        let yAxisAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        yAxisLabel.draw(at: NSPoint(x: 8, y: bounds.height - 20), withAttributes: yAxisAttributes)
        
        // X ekseni etiketi
        let xAxisLabel = "Zaman (Gün)" as NSString
        let xAxisSize = xAxisLabel.size(withAttributes: yAxisAttributes)
        xAxisLabel.draw(at: NSPoint(x: bounds.width - xAxisSize.width - 10, y: 8), withAttributes: yAxisAttributes)
    }
    
    private func drawChartTitle() {
        guard !candlesticks.isEmpty else { return }
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: NSColor.labelColor
        ]
        
        let statsAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        // Fiyat istatistiklerini hesapla
        let currentPrice = candlesticks.last?.weightedAverage ?? 0
        let firstPrice = candlesticks.first?.weightedAverage ?? 0
        let priceChange = currentPrice - firstPrice
        let priceChangePercent = firstPrice > 0 ? (priceChange / firstPrice) * 100 : 0
        
        let titleText = "📈 Günlük Mum Grafik Analizi" as NSString
        let titleSize = titleText.size(withAttributes: titleAttributes)
        titleText.draw(at: NSPoint(x: (bounds.width - titleSize.width) / 2, y: 8), withAttributes: titleAttributes)
        
        // Fiyat değişim bilgisi
        let changeSymbol = priceChange >= 0 ? "▲" : "▼"
        let changeColor = priceChange >= 0 ? NSColor.systemGreen : NSColor.systemRed
        
        let changeText = String(format: "Son Fiyat: %.2f  %@ %+.2f (%+.2f%%)", currentPrice, changeSymbol, priceChange, priceChangePercent) as NSString
        let changeTextSize = changeText.size(withAttributes: statsAttributes)
        
        let changeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: changeColor
        ]
        
        changeText.draw(at: NSPoint(x: bounds.width - changeTextSize.width - 10, y: bounds.height - 20), withAttributes: changeAttributes)
        
        // Bilgi notu
        let infoText = "🖱️ Fare ile üzerine gel → Detay | Tıkla → Tam bilgi" as NSString
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
        infoText.draw(at: NSPoint(x: 10, y: 8), withAttributes: infoAttributes)
    }
    private func drawMouseCrosshair(
        chartRect: NSRect,
        yMin: Double,
        yMax: Double,
        xScale: CGFloat
    ) {

        guard let mouseLocation = mouseLocation else { return }
        guard chartRect.contains(mouseLocation) else { return }

        // MARK: Yatay çizgi

        let horizontalPath = NSBezierPath()

        horizontalPath.move(
            to: NSPoint(
                x: chartRect.minX,
                y: mouseLocation.y
            )
        )

        horizontalPath.line(
            to: NSPoint(
                x: chartRect.maxX,
                y: mouseLocation.y
            )
        )

        horizontalPath.lineWidth = 0.75

        horizontalPath.setLineDash(
            [4,4],
            count: 2,
            phase: 0
        )

        NSColor.secondaryLabelColor
            .withAlphaComponent(0.25)
            .setStroke()

        horizontalPath.stroke()

        // MARK: Dikey çizgi

        let verticalPath = NSBezierPath()

        verticalPath.move(
            to: NSPoint(
                x: mouseLocation.x,
                y: chartRect.minY
            )
        )

        verticalPath.line(
            to: NSPoint(
                x: mouseLocation.x,
                y: chartRect.maxY
            )
        )

        verticalPath.lineWidth = 0.75

        verticalPath.setLineDash(
            [4,4],
            count: 2,
            phase: 0
        )

        NSColor.secondaryLabelColor
            .withAlphaComponent(0.18)
            .setStroke()

        verticalPath.stroke()

        // MARK: Fiyat etiketi

        let ratio =
            (mouseLocation.y - chartRect.minY)
            / chartRect.height

        let price =
            yMin +
            Double(ratio)
            * (yMax - yMin)

        drawPriceBadge(
            text: String(format: "%.2f", price),
            x: chartRect.maxX + 4,
            y: mouseLocation.y
        )

        // MARK: Tarih etiketi

        guard !candlesticks.isEmpty else { return }

        let index = Int(
            round(
                (mouseLocation.x - chartRect.minX)
                / xScale
            )
        )

        guard index >= 0,
              index < candlesticks.count
        else { return }

        let stick = candlesticks[index]

        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"

        let dateText =
            formatter.string(from: stick.date)

        drawDateBadge(
            text: dateText,
            x: chartRect.minX + CGFloat(index) * xScale,
            y: chartRect.minY - 26
        )
    }
    
    private func drawPriceBadge(
        text: String,
        x: CGFloat,
        y: CGFloat
    ) {

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(
                ofSize: 10,
                weight: .medium
            ),
            .foregroundColor: NSColor.labelColor
        ]

        let size =
            (text as NSString)
                .size(withAttributes: attrs)

        let rect = NSRect(
            x: x,
            y: y - 9,
            width: size.width + 10,
            height: 18
        )

        NSColor.controlBackgroundColor
            .withAlphaComponent(0.95)
            .setFill()

        NSBezierPath(
            roundedRect: rect,
            xRadius: 4,
            yRadius: 4
        ).fill()

        (text as NSString).draw(
            at: NSPoint(
                x: rect.minX + 5,
                y: rect.minY + 3
            ),
            withAttributes: attrs
        )
    }
    private func drawDateBadge(
        text: String,
        x: CGFloat,
        y: CGFloat
    ) {

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.labelColor
        ]

        let size =
            (text as NSString)
                .size(withAttributes: attrs)

        let rect = NSRect(
            x: x - (size.width + 12) / 2,
            y: y,
            width: size.width + 12,
            height: 18
        )

        NSColor.controlBackgroundColor
            .withAlphaComponent(0.95)
            .setFill()

        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: 4,
            yRadius: 4
        )

        path.fill()

        (text as NSString).draw(
            at: NSPoint(
                x: rect.minX + 6,
                y: rect.minY + 3
            ),
            withAttributes: attrs
        )
    }
    /*
    private func drawMouseCrosshair(chartRect: NSRect) {

        guard let mouseLocation = mouseLocation else { return }
        guard chartRect.contains(mouseLocation) else { return }

        let path = NSBezierPath()

        path.move(to: NSPoint(
            x: chartRect.minX,
            y: mouseLocation.y
        ))

        path.line(to: NSPoint(
            x: chartRect.maxX,
            y: mouseLocation.y
        ))

        path.lineWidth = 0.75

        let dashPattern: [CGFloat] = [4, 4]
        path.setLineDash(
            dashPattern,
            count: dashPattern.count,
            phase: 0
        )

        NSColor.secondaryLabelColor
            .withAlphaComponent(0.25)
            .setStroke()

        path.stroke()
    }
    */
    // MARK: - Resize Handling
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        needsDisplay = true
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsDisplay = true
        updateTrackingAreas()
    }

    func resetVisibleRange() {

        guard !candlesticks.isEmpty else { return }

        firstVisibleBar = max(0, candlesticks.count - visibleBarCount)

        needsDisplay = true
    }
}
