import Cocoa

final class ChartInteractionController {

    // MARK: - Public

    var viewport: ChartViewport!

    /// Her viewport değiştiğinde grafik yeniden çizilsin
    var onViewportChanged: (() -> Void)?

    /// Sağ-sol okta kaç bar kayacak
    var keyboardStep: Int = 20

    // MARK: - Zoom Limits

    private let minimumVisibleBars = 20
    private let maximumVisibleBars = 500

    // MARK: - Mouse Drag

    private var dragStartPoint: CGPoint?
    private var dragStartFirstBar: Int = 0

    // MARK: - Mouse Down

    func mouseDown(at point: CGPoint) {

        dragStartPoint = point

        dragStartFirstBar =
            viewport.firstVisibleBar
    }

    // MARK: - Mouse Dragged

    func mouseDragged(
        to point: CGPoint,
        chartWidth: CGFloat
    ) {

        guard
            let start = dragStartPoint,
            chartWidth > 0
        else {
            return
        }

        let dx =
            point.x - start.x

        let barsPerPixel =
            Double(viewport.visibleBarCount) /
            Double(chartWidth)

        let deltaBars =
            Int(
                round(
                    Double(dx) *
                    barsPerPixel
                )
            )

        viewport.setFirstVisibleBar(
            dragStartFirstBar -
            deltaBars
        )

        viewport.clamp()

        onViewportChanged?()
    }

    // MARK: - Mouse Up

    func mouseUp() {

        dragStartPoint = nil
    }

    // MARK: - Keyboard

    func moveLeft() {

        viewport.scrollLeft(
            by: keyboardStep
        )

        onViewportChanged?()
    }

    func moveRight() {

        viewport.scrollRight(
            by: keyboardStep
        )

        onViewportChanged?()
    }

    // MARK: - Mouse Wheel Zoom

    func zoomWithWheel(
        delta: CGFloat
    ) {

        guard
            delta != 0,
            viewport.totalBarCount > 0
        else {
            return
        }

        let zoomAmount =
            max(
                1,
                Int(
                    abs(delta)
                )
            )

        let totalBars =
            viewport.totalBarCount

        // -------------------------------------------------
        // Wheel yukarı:
        // YAKINLAŞ
        //
        // Wheel aşağı:
        // UZAKLAŞ
        // -------------------------------------------------

        if delta > 0 {

            // ---------------------------------------------
            // YAKINLAŞ
            // ---------------------------------------------

            let currentVisible =
                min(
                    viewport.visibleBarCount,
                    totalBars
                )

            let newVisible =
                max(
                    minimumVisibleBars,
                    currentVisible -
                    zoomAmount
                )

            viewport.visibleBarCount =
                newVisible

        } else {

            // ---------------------------------------------
            // UZAKLAŞ
            // ---------------------------------------------

            let currentVisible =
                min(
                    viewport.visibleBarCount,
                    totalBars
                )

            let newVisible =
                min(
                    totalBars,
                    min(
                        maximumVisibleBars,
                        currentVisible +
                        zoomAmount
                    )
                )

            viewport.visibleBarCount =
                newVisible
        }

        viewport.clamp()

        onViewportChanged?()
    }

    // MARK: - Programmatic Zoom

    func zoom(
        by delta: Int
    ) {

        guard
            viewport.totalBarCount > 0
        else {
            return
        }

        let totalBars =
            viewport.totalBarCount

        let currentVisible =
            min(
                viewport.visibleBarCount,
                totalBars
            )

        let newVisible =
            max(
                minimumVisibleBars,
                min(
                    maximumVisibleBars,
                    currentVisible -
                    delta
                )
            )

        viewport.visibleBarCount =
            newVisible

        viewport.clamp()

        onViewportChanged?()
    }
}
