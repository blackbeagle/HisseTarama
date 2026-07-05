import Cocoa

final class SMARenderer {

    var coordinateSystem: ChartCoordinateSystem!
    var theme: ChartTheme = .default

    /// period -> sma values
    var activeSMAs: [Int:[Double?]] = [:]

    func draw() {

        guard !activeSMAs.isEmpty else { return }

        let chart = coordinateSystem!

        for (period, smaValues) in activeSMAs {

            drawPeriod(
                period: period,
                values: smaValues,
                coordinateSystem: chart
            )
        }
    }

    // MARK: -

    private func drawPeriod(
        period: Int,
        values: [Double?],
        coordinateSystem: ChartCoordinateSystem
    ) {

        guard
            let viewport = coordinateSystem.viewport
        else {
            return
        }

        let color =
            theme.smaColors[period]
            ?? .systemGray

        color.setStroke()

        let path = NSBezierPath()

        var firstPoint = true

        let range = viewport.visibleRange()

        for globalIndex in range {

            guard globalIndex < values.count else {
                continue
            }

            guard let value = values[globalIndex] else {
                continue
            }

            let visibleIndex =
                globalIndex - viewport.firstVisibleBar

            let x =
                coordinateSystem.x(
                    forVisibleIndex: visibleIndex
                )

            let y =
                coordinateSystem.y(
                    forPrice: value
                )

            if firstPoint {

                path.move(to: NSPoint(x: x, y: y))

                firstPoint = false

            } else {

                path.line(to: NSPoint(x: x, y: y))
            }
        }

        path.lineWidth = theme.smaLineWidth

        path.stroke()
    }
}
