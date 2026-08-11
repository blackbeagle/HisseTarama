
import Cocoa

final class GridRenderer {

    // MARK: - Properties

    var coordinateSystem: ChartCoordinateSystem!

    var theme: ChartTheme = .default

    private let calculator = AdaptiveGridCalculator()

    // MARK: - Draw

    func draw() {

        guard let chart = coordinateSystem else {
            return
        }

        guard !chart.visibleCandles.isEmpty else {
            return
        }

        drawHorizontalGrid(chart: chart)
        drawVerticalGrid(chart: chart)
    }
}

// MARK: - Horizontal Grid

private extension GridRenderer {

    func drawHorizontalGrid(
        chart: ChartCoordinateSystem
    ) {

        let visibleBars =
            chart.visibleCandles.count

        let targetLines =
            calculator.horizontalGridCount(
                visibleBars: visibleBars
            )

        let levels =
            calculator.priceLevels(
                minPrice: chart.minPrice,
                maxPrice: chart.maxPrice,
                targetLines: targetLines
            )

        guard !levels.isEmpty else {
            return
        }

        NSColor.separatorColor
            .withAlphaComponent(0.25)
            .setStroke()

        for price in levels {

            let y =
                chart.y(
                    forPrice: price
                )

            guard
                y >= chart.chartRect.minY,
                y <= chart.chartRect.maxY
            else {
                continue
            }

            let path = NSBezierPath()

            path.move(
                to: NSPoint(
                    x: chart.chartRect.minX,
                    y: y
                )
            )

            path.line(
                to: NSPoint(
                    x: chart.chartRect.maxX,
                    y: y
                )
            )

            path.lineWidth = 0.5

            path.stroke()
        }
    }
}

// MARK: - Vertical Grid

private extension GridRenderer {

    func drawVerticalGrid(
        chart: ChartCoordinateSystem
    ) {

        let visibleBars =
            chart.visibleCandles.count

        guard visibleBars > 0 else {
            return
        }

        let step =
            calculator.verticalStep(
                visibleBars: visibleBars
            )

        guard step > 0 else {
            return
        }

        NSColor.separatorColor
            .withAlphaComponent(0.25)
            .setStroke()

        var index = 0

        while index < visibleBars {

            let x =
                chart.x(
                    forVisibleIndex: index
                )

            let path = NSBezierPath()

            path.move(
                to: NSPoint(
                    x: x,
                    y: chart.chartRect.minY
                )
            )

            path.line(
                to: NSPoint(
                    x: x,
                    y: chart.chartRect.maxY
                )
            )

            path.lineWidth = 0.5

            path.stroke()

            index += step
        }
    }
}


