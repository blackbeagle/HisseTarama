import Cocoa

final class SMARenderer {

    var coordinateSystem: ChartCoordinateSystem!

    var theme: ChartTheme = .default

    /// period -> SMA values
    var activeSMAs: [Int: [Double?]] = [:]

    // MARK: - Draw

    func draw() {

        guard !activeSMAs.isEmpty else {
            return
        }

        let chart = coordinateSystem!

        for (period, smaValues) in activeSMAs {

            drawPeriod(
                period: period,
                values: smaValues,
                coordinateSystem: chart
            )
        }
    }

    // MARK: - Draw Period

    private func drawPeriod(
        period: Int,
        values: [Double?],
        coordinateSystem: ChartCoordinateSystem
    ) {

        guard
            let viewport =
                coordinateSystem.viewport
        else {
            return
        }

        // -------------------------------------------------
        // SMA COLOR
        // -------------------------------------------------

        let color =
            theme.smaColors[period]
            ?? .systemGray

        color.setStroke()

        // -------------------------------------------------
        // SMA LINE WIDTH
        // -------------------------------------------------

        let lineWidth =
            theme.smaLineWidths[period]
            ?? theme.smaLineWidth

        // -------------------------------------------------
        // Path
        // -------------------------------------------------

        let path =
            NSBezierPath()

        var firstPoint = true

        let range =
            viewport.visibleRange()

        for globalIndex in range {

            guard
                globalIndex >= 0,
                globalIndex < values.count
            else {
                continue
            }

            guard
                let value =
                    values[globalIndex]
            else {
                // SMA'nın henüz hesaplanamadığı
                // noktalar için çizgiyi kes.
                firstPoint = true
                continue
            }

            let visibleIndex =
                globalIndex -
                viewport.firstVisibleBar

            let x =
                coordinateSystem.x(
                    forVisibleIndex:
                        visibleIndex
                )

            let y =
                coordinateSystem.y(
                    forPrice:
                        value
                )

            let point =
                NSPoint(
                    x: x,
                    y: y
                )

            if firstPoint {

                path.move(
                    to: point
                )

                firstPoint = false

            } else {

                path.line(
                    to: point
                )
            }
        }

        path.lineWidth =
            lineWidth

        path.stroke()
    }
}
