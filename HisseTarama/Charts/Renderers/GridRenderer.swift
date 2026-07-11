import Cocoa

final class GridRenderer {

    var coordinateSystem: ChartCoordinateSystem!

    var theme: ChartTheme = .default

    private let calculator =
        AdaptiveGridCalculator()

    func draw() {

        drawHorizontalGrid()

        drawVerticalGrid()
    }
}

private extension GridRenderer {

    func drawHorizontalGrid() {

        let chart = coordinateSystem!

        let count =
        calculator.horizontalGridCount(
            visibleBars: chart.visibleCandles.count
        )

        NSColor.separatorColor
            .withAlphaComponent(0.25)
            .setStroke()

        for i in 0...count {

            let y =
            chart.chartRect.minY +
            CGFloat(i) *
            chart.chartRect.height /
            CGFloat(count)

            let path = NSBezierPath()

            path.move(
                to: CGPoint(
                    x: chart.chartRect.minX,
                    y: y
                )
            )

            path.line(
                to: CGPoint(
                    x: chart.chartRect.maxX,
                    y: y
                )
            )

            path.lineWidth = 0.5

            path.stroke()
        }
    }
}

private extension GridRenderer {

    func drawVerticalGrid() {

        let chart = coordinateSystem!

        let step =
        calculator.verticalStep(
            visibleBars: chart.visibleCandles.count
        )

        NSColor.separatorColor
            .withAlphaComponent(0.25)
            .setStroke()

        var index = 0

        while index < chart.visibleCandles.count {

            let x =
            chart.x(
                forVisibleIndex: index
            )

            let path = NSBezierPath()

            path.move(
                to: CGPoint(
                    x: x,
                    y: chart.chartRect.minY
                )
            )

            path.line(
                to: CGPoint(
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
