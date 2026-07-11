// CandlestickChartView.swift
import Cocoa

class CandlestickChartView: NSView {
   
    // MARK: - Properties
   
    // MARK: - Chart Core
    private let viewport = ChartViewport()

    private let coordinateSystem = ChartCoordinateSystem()

    private let interaction = ChartInteractionController()

    private let theme = ChartTheme.default

    // MARK: - Renderers
    private let gridRenderer = GridRenderer()

    private let candleRenderer = CandleRenderer()

    private let smaRenderer = SMARenderer()

    private let selectionRenderer = SelectionOverlayRenderer()

    private let axisRenderer = AxisRenderer()
    
    private var mouseLocation: CGPoint = .zero
    
    // Grafik kenar boşlukları
    private let leftMargin: CGFloat = 55
    private let rightMargin: CGFloat = 35
    private let topMargin: CGFloat = 35
    private let bottomMargin: CGFloat = 45
    
    // Fare takibi için
    private var trackingArea: NSTrackingArea?
    private var highlightedIndex: Int?
    
    var activeSMAs: [Int: [Double?]] = [:]
  
    // Fare sürükleme
    private var lastDragPoint: NSPoint?
    
    var candlesticks: [Candlestick] = [] {
        didSet {

            firstVisibleBar = max(0, candlesticks.count - visibleBarCount)

            needsDisplay = true
        }
    }
    
    private var visibleCandles: [Candlestick] {
        guard !candlesticks.isEmpty else { return [] }

        let start = max(0, firstVisibleBar)
        let end = min(start + visibleBarCount, candlesticks.count)

        return Array(candlesticks[start..<end])
    }
    
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
        layer?.backgroundColor = theme.backgroundColor.cgColor

        autoresizingMask = [.width, .height]

        interaction.viewport = viewport

        interaction.onViewportChanged = { [weak self] in
            self?.needsDisplay = true
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        window?.makeFirstResponder(self)
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
 
  
    override func mouseMoved(with event: NSEvent) {

        let location = convert(event.locationInWindow, from: nil)

        mouseLocation = location

        highlightedIndex =
            coordinateSystem.visibleIndex(atX: location.x)

        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {

        highlightedIndex = nil

        needsDisplay = true
    }
    
    
    override func mouseDown(with event: NSEvent) {

        let location = convert(event.locationInWindow, from: nil)

        interaction.mouseDown(at: location)

        // Mouse üzerindeki mumu da seç
        if let index = coordinateSystem.visibleIndex(atX: location.x) {
            highlightedIndex = index
            needsDisplay = true
        }
    }
    
    override func mouseDragged(with event: NSEvent) {

        let location = convert(event.locationInWindow, from: nil)

        interaction.mouseDragged(
            to: location,
            chartWidth: coordinateSystem.chartRect.width
        )

        // Drag sırasında highlight'ı değiştirmiyoruz.
        // TradingView davranışı.
    }
    
  
    
    override func mouseUp(with event: NSEvent) {

        interaction.mouseUp()
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
    
    override func keyDown(with event: NSEvent) {

        switch event.keyCode {

        case 123:   // ←

            interaction.moveLeft()

        case 124:   // →

            interaction.moveRight()

        default:

            super.keyDown(with: event)
        }
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

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.setFillColor(NSColor.controlBackgroundColor.cgColor)
        context.fill(dirtyRect)

        guard !candlesticks.isEmpty else {
            drawEmptyState()
            return
        }
        
        //----------------------------------------------------
        // Viewport
        //----------------------------------------------------

        viewport.update(totalBars: candlesticks.count)
        
        //----------------------------------------------------
        //Coordinate System
        //----------------------------------------------------

        coordinateSystem.viewport = viewport
        coordinateSystem.candles = candlesticks
        coordinateSystem.chartRect = getChartRect()

        guard !coordinateSystem.visibleCandles.isEmpty else {
            return
        }

        
        //----------------------------------------------------
        // Render
        //----------------------------------------------------

        // GRID
        gridRenderer.coordinateSystem = coordinateSystem
        gridRenderer.theme = theme
        gridRenderer.draw()
        
        candleRenderer.coordinateSystem = coordinateSystem
        candleRenderer.theme = theme
        candleRenderer.draw()
        
        smaRenderer.coordinateSystem = coordinateSystem
        smaRenderer.theme = theme
        smaRenderer.activeSMAs = activeSMAs
        smaRenderer.draw()
        
        selectionRenderer.coordinateSystem = coordinateSystem
        selectionRenderer.theme = theme
        selectionRenderer.view = self
        selectionRenderer.highlightedIndex = highlightedIndex
        selectionRenderer.draw()

        axisRenderer.coordinateSystem = coordinateSystem
        axisRenderer.theme = theme
        axisRenderer.view = self
        axisRenderer.draw()

        
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
    
    gridRenderer.coordinateSystem = coordinateSystem
    gridRenderer.draw()
     
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
    
    
    private func drawAxisLabels() {

        let chartRect = coordinateSystem.chartRect
        let candles = coordinateSystem.visibleCandles

        guard !candles.isEmpty else { return }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        //--------------------------------------------------
        // Y EKSENİ
        //--------------------------------------------------

        let labelCount = 5

        for i in 0...labelCount {

            let ratio = Double(i) / Double(labelCount)

            let price = coordinateSystem.minPrice +
                (coordinateSystem.maxPrice - coordinateSystem.minPrice) * ratio

            let y = chartRect.minY +
                CGFloat(ratio) * chartRect.height

            let label = NSString(format: "%.2f", price)

            let size = label.size(withAttributes: attributes)

            label.draw(
                at: NSPoint(
                    x: 8,
                    y: y - size.height / 2
                ),
                withAttributes: attributes
            )
        }

        //--------------------------------------------------
        // X EKSENİ
        //--------------------------------------------------

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "tr_TR")

        let first = candles.first!
        let last = candles.last!

        let firstLabel = formatter.string(from: first.date) as NSString
        let lastLabel = formatter.string(from: last.date) as NSString

        let firstSize = firstLabel.size(withAttributes: attributes)
        let lastSize = lastLabel.size(withAttributes: attributes)

        firstLabel.draw(
            at: NSPoint(
                x: chartRect.minX,
                y: chartRect.maxY + 8
            ),
            withAttributes: attributes
        )

        lastLabel.draw(
            at: NSPoint(
                x: chartRect.maxX - lastSize.width,
                y: chartRect.maxY + 8
            ),
            withAttributes: attributes
        )

        //--------------------------------------------------
        // ORTA TARİH
        //--------------------------------------------------

        let middleIndex = candles.count / 2

        if middleIndex > 0 && middleIndex < candles.count {

            let middle = candles[middleIndex]

            let middleLabel =
                formatter.string(from: middle.date) as NSString

            let middleSize =
                middleLabel.size(withAttributes: attributes)

            let x =
                coordinateSystem.x(forVisibleIndex: middleIndex)

            middleLabel.draw(
                at: NSPoint(
                    x: x - middleSize.width / 2,
                    y: chartRect.maxY + 8
                ),
                withAttributes: attributes
            )
        }

        //--------------------------------------------------
        // Başlıklar
        //--------------------------------------------------

        let smallAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]

        ("Fiyat (₺)" as NSString).draw(
            at: NSPoint(x: 8, y: bounds.height - 18),
            withAttributes: smallAttributes
        )

        ("Zaman" as NSString).draw(
            at: NSPoint(
                x: bounds.width - 55,
                y: 8
            ),
            withAttributes: smallAttributes
        )
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
