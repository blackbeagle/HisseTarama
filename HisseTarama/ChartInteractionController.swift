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

    func mouseDragged(to point: CGPoint,
                      chartWidth: CGFloat)
    {
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
            Int(round(Double(dx) * barsPerPixel))

        viewport.setFirstVisibleBar(dragStartFirstBar - deltaBars)

        viewport.clamp()

        onViewportChanged?()
    }

    func mouseUp() {

        dragStartPoint = nil
    }

    // MARK: - Keyboard

    func moveLeft() {

        viewport.scrollLeft(by: keyboardStep)

        onViewportChanged?()

        
    }

    func moveRight() {

        viewport.scrollRight(by: keyboardStep)

        onViewportChanged?()
    }

    // MARK: - Mouse Wheel (ileride zoom olacak)

    func scrollWheel(deltaX: CGFloat) {

        guard deltaX != 0 else { return }

        viewport.scroll(by: Int(deltaX))

        onViewportChanged?()
    }

    // MARK: - Zoom (şimdilik kullanılmayacak)

    func zoom(by delta: Int) {

        viewport.visibleBarCount -= delta

        viewport.visibleBarCount =
            max(20,
                min(500,
                    viewport.visibleBarCount))

        viewport.clamp()

        onViewportChanged?()
    }
}


