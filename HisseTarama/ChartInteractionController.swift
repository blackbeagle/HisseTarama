import Cocoa

final class ChartInteractionController {

    // MARK: - Public

    var viewport: ChartViewport!

    /// Her viewport değiştiğinde grafik yeniden çizilsin
    var onViewportChanged: (() -> Void)?

    // Sağ-sol okta kaç bar kayacak
    var keyboardStep: Int = 20

    // Mouse sürükleme başlangıcı
    private var dragStartPoint: CGPoint?
    private var dragStartFirstBar: Int = 0

    // MARK: - Mouse

    func mouseDown(at point: CGPoint) {

        dragStartPoint = point
        dragStartFirstBar = viewport.firstVisibleBar
    }

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

        let dx = point.x - start.x

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
            dragStartFirstBar - deltaBars
        )

        viewport.clamp()

        onViewportChanged?()
    }

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

        guard delta != 0 else {
            return
        }

        let zoomAmount =
            max(
                1,
                Int(
                    abs(delta)
                )
            )

        if delta > 0 {

            // Wheel yukarı:
            // daha fazla bar göster → uzaklaş

            viewport.visibleBarCount +=
                zoomAmount

        } else {

            // Wheel aşağı:
            // daha az bar göster → yakınlaş

            viewport.visibleBarCount -=
                zoomAmount
        }

        viewport.visibleBarCount =
            max(
                20,
                min(
                    500,
                    viewport.visibleBarCount
                )
            )

        viewport.clamp()

        onViewportChanged?()
    }

    // MARK: - Zoom

    func zoom(by delta: Int) {

        viewport.visibleBarCount -= delta

        viewport.visibleBarCount =
            max(
                20,
                min(
                    500,
                    viewport.visibleBarCount
                )
            )

        viewport.clamp()

        onViewportChanged?()
    }
}
