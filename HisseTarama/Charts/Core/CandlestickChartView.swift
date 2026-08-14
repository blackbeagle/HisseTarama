import Cocoa

final class CandlestickChartView: NSView {

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

    // MARK: - Layout

    private let leftMargin: CGFloat = 55
    private let rightMargin: CGFloat = 75
    private let topMargin: CGFloat = 35
    private let bottomMargin: CGFloat = 58

    // MARK: - Tracking

    private var trackingArea: NSTrackingArea?

    private var highlightedGlobalIndex: Int?

    private var crosshairPoint: CGPoint?

    // MARK: - Data

    var candlesticks: [Candlestick] = [] {

        didSet {

            viewport.update(
                totalBars: candlesticks.count
            )

            needsDisplay = true
        }
    }

    var activeSMAs: [Int: [Double?]] = [:]

    var symbol: String = ""

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {

        super.init(frame: frameRect)

        setupView()
    }

    required init?(coder: NSCoder) {

        super.init(coder: coder)

        setupView()
    }

    // MARK: - Setup

    private func setupView() {

        wantsLayer = true

        layer?.backgroundColor =
            theme.backgroundColor.cgColor

        autoresizingMask = [
            .width,
            .height
        ]

        interaction.viewport = viewport

        interaction.onViewportChanged = { [weak self] in

            self?.needsDisplay = true
        }
    }

    override func viewDidMoveToWindow() {

        super.viewDidMoveToWindow()

        window?.makeFirstResponder(self)
    }

    override var acceptsFirstResponder: Bool {

        true
    }

    // MARK: - Tracking Area

    override func updateTrackingAreas() {

        super.updateTrackingAreas()

        if let area = trackingArea {

            removeTrackingArea(area)
        }

        trackingArea = NSTrackingArea(

            rect: bounds,

            options: [
                .activeAlways,
                .mouseMoved,
                .mouseEnteredAndExited,
                .inVisibleRect
            ],

            owner: self,

            userInfo: nil
        )

        if let area = trackingArea {

            addTrackingArea(area)
        }
    }

    // MARK: - Mouse

    override func mouseMoved(with event: NSEvent) {

        let point =
            convert(
                event.locationInWindow,
                from: nil
            )

        let chartRect =
            coordinateSystem.chartRect

        guard chartRect.contains(point) else {

            highlightedGlobalIndex = nil

            crosshairPoint = nil

            needsDisplay = true

            return
        }

        crosshairPoint = point

        guard let visibleIndex =
                coordinateSystem.visibleIndex(
                    atX: point.x
                )
        else {

            highlightedGlobalIndex = nil

            needsDisplay = true

            return
        }

        highlightedGlobalIndex =
            coordinateSystem.globalIndex(
                fromVisibleIndex: visibleIndex
            )

        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {

        highlightedGlobalIndex = nil

        crosshairPoint = nil

        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {

        let point =
            convert(
                event.locationInWindow,
                from: nil
            )

        interaction.mouseDown(
            at: point
        )

        let chartRect =
            coordinateSystem.chartRect

        if chartRect.contains(point) {

            crosshairPoint = point

            if let visibleIndex =
                coordinateSystem.visibleIndex(
                    atX: point.x
                ) {

                highlightedGlobalIndex =
                    coordinateSystem.globalIndex(
                        fromVisibleIndex: visibleIndex
                    )

            } else {

                highlightedGlobalIndex = nil
            }

        } else {

            crosshairPoint = nil

            highlightedGlobalIndex = nil
        }

        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {

        let point =
            convert(
                event.locationInWindow,
                from: nil
            )

        crosshairPoint = point

        if let visibleIndex =
            coordinateSystem.visibleIndex(
                atX: point.x
            ) {

            highlightedGlobalIndex =
                coordinateSystem.globalIndex(
                    fromVisibleIndex: visibleIndex
                )
        }

        interaction.mouseDragged(

            to: point,

            chartWidth:
                coordinateSystem.chartRect.width
        )

        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {

        interaction.mouseUp()
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {

        switch event.keyCode {

        case 123:

            interaction.moveLeft()

        case 124:

            interaction.moveRight()

        default:

            super.keyDown(with: event)
        }
    }

    // MARK: - Helpers

    private func getChartRect() -> NSRect {

        NSRect(

            x: leftMargin,

            y: bottomMargin,

            width:
                max(
                    0,
                    bounds.width -
                    leftMargin -
                    rightMargin
                ),

            height:
                max(
                    0,
                    bounds.height -
                    topMargin -
                    bottomMargin
                )
        )
    }

    // MARK: - Public Viewport Control

    /// Grafik üzerinde gösterilecek bar sayısını ayarlar.
    /// Periyot değişimlerinde ChartDetailViewController
    /// tarafından kullanılır.
    func setVisibleBarCount(_ count: Int) {

        viewport.visibleBarCount =
            max(
                20,
                min(
                    500,
                    count
                )
            )

        viewport.update(
            totalBars: candlesticks.count
        )

        viewport.moveToLast()

        needsDisplay = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {

        guard
            let context =
                NSGraphicsContext.current?.cgContext
        else {
            return
        }

        context.setFillColor(
            theme.backgroundColor.cgColor
        )

        context.fill(bounds)

        guard !candlesticks.isEmpty else {

            drawEmptyState()

            return
        }

        // MARK: Viewport

        viewport.update(
            totalBars: candlesticks.count
        )

        // MARK: Coordinate System

        coordinateSystem.viewport =
            viewport

        coordinateSystem.candles =
            candlesticks

        coordinateSystem.chartRect =
            getChartRect()

        coordinateSystem.prepare()

        guard
            !coordinateSystem.visibleCandles.isEmpty
        else {
            return
        }

        // MARK: Grid

        gridRenderer.coordinateSystem =
            coordinateSystem

        gridRenderer.theme =
            theme

        gridRenderer.draw()

        // MARK: Candles

        candleRenderer.coordinateSystem =
            coordinateSystem

        candleRenderer.theme =
            theme

        candleRenderer.draw()

        // MARK: SMA

        smaRenderer.coordinateSystem =
            coordinateSystem

        smaRenderer.theme =
            theme

        smaRenderer.activeSMAs =
            activeSMAs

        smaRenderer.draw()

        // MARK: Selection

        selectionRenderer.coordinateSystem =
            coordinateSystem

        selectionRenderer.theme =
            theme

        selectionRenderer.view =
            self

        selectionRenderer.crosshairPoint =
            crosshairPoint

        selectionRenderer.activeSMAs =
            activeSMAs

        if let globalIndex =
            highlightedGlobalIndex,
           let visibleIndex =
            coordinateSystem.visibleIndex(
                fromGlobalIndex: globalIndex
            ) {

            selectionRenderer.highlightedIndex =
                visibleIndex

        } else {

            selectionRenderer.highlightedIndex =
                nil
        }

        selectionRenderer.draw()

        // MARK: Axis

        axisRenderer.coordinateSystem =
            coordinateSystem

        axisRenderer.theme =
            theme

        axisRenderer.view =
            self

        axisRenderer.draw()

        // MARK: Title

        drawChartTitle()
    }

    // MARK: - Empty State

    private func drawEmptyState() {

        let text =
            "Grafik verisi bulunamadı." as NSString

        let attributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    NSFont.systemFont(
                        ofSize: 18
                    ),

                .foregroundColor:
                    NSColor.secondaryLabelColor
            ]

        let size =
            text.size(
                withAttributes: attributes
            )

        text.draw(

            at: CGPoint(

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

    // MARK: - Title

    private func drawChartTitle() {

        let title =
            "\(candlesticks.count) Bar" as NSString

        let attributes:
            [NSAttributedString.Key: Any] = [

                .font:
                    NSFont.boldSystemFont(
                        ofSize: 14
                    ),

                .foregroundColor:
                    theme.axisTitleColor
            ]

        title.draw(

            at: CGPoint(

                x: 12,

                y:
                    bounds.height - 24
            ),

            withAttributes:
                attributes
        )
    }

    // MARK: - Public

    func resetVisibleRange() {

        viewport.moveToLast()

        needsDisplay = true
    }

    func reloadChart() {

        viewport.update(
            totalBars: candlesticks.count
        )

        needsDisplay = true
    }

    // MARK: - Resize

    override func setFrameSize(
        _ newSize: NSSize
    ) {

        super.setFrameSize(
            newSize
        )

        needsDisplay = true
    }

    override func viewDidEndLiveResize() {

        super.viewDidEndLiveResize()

        needsDisplay = true
    }

    // MARK: - Scroll Wheel Zoom

    override func scrollWheel(
        with event: NSEvent
    ) {

        interaction.zoomWithWheel(
            delta:
                event.scrollingDeltaY
        )
    }

    // MARK: - Deinit

    deinit {

        if let trackingArea = trackingArea {

            removeTrackingArea(
                trackingArea
            )
        }
    }
}
