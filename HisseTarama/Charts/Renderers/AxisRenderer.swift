import Cocoa

final class AxisRenderer {


weak var view: NSView?

var coordinateSystem: ChartCoordinateSystem!

var theme: ChartTheme = .default

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "tr_TR")
    formatter.dateFormat = "dd MMM"
    return formatter
}()

func draw() {

    guard view != nil else { return }
    guard let coordinateSystem = coordinateSystem else { return }

    let chartRect = coordinateSystem.chartRect
    let candles = coordinateSystem.visibleCandles

    guard !candles.isEmpty else { return }

    let labelAttributes: [NSAttributedString.Key: Any] = [

        .font: NSFont.systemFont(ofSize: 11),

        .foregroundColor: theme.axisLabelColor
    ]

    let calculator = AdaptiveGridCalculator()

    let targetLines =
        calculator.horizontalGridCount(
            visibleBars: candles.count
        )

    let levels =
        calculator.priceLevels(
            minPrice: coordinateSystem.minPrice,
            maxPrice: coordinateSystem.maxPrice,
            targetLines: targetLines
        )

    for price in levels {

        let y =
            coordinateSystem.y(
                forPrice: price
            )

        guard
            y >= chartRect.minY,
            y <= chartRect.maxY
        else {
            continue
        }

        let text =
            NSString(format: "%.2f", price)

        let size =
            text.size(
                withAttributes: labelAttributes
            )

        text.draw(
            at: NSPoint(
                x: chartRect.maxX + 8,
                y: y - size.height / 2
            ),
            withAttributes: labelAttributes
        )
    }

    drawXAxisDates(
        candles: candles,
        chartRect: chartRect,
        attributes: labelAttributes
    )

    let titleAttributes:
        [NSAttributedString.Key: Any] = [

            .font:
                NSFont.systemFont(ofSize: 10),

            .foregroundColor:
                theme.axisTitleColor
        ]

    let priceTitle = "Fiyat (₺)" as NSString

    priceTitle.draw(
        at: NSPoint(
            x: chartRect.maxX + 8,
            y: chartRect.maxY + 12
        ),
        withAttributes: titleAttributes
    )

    let time = "Zaman" as NSString

    let timeSize =
        time.size(
            withAttributes: titleAttributes
        )

    time.draw(
        at: NSPoint(
            x: chartRect.maxX - timeSize.width,
            y: 8
        ),
        withAttributes: titleAttributes
    )
}

private func drawXAxisDates(
    candles: [Candlestick],
    chartRect: CGRect,
    attributes: [NSAttributedString.Key: Any]
) {

    guard !candles.isEmpty else {
        return
    }

    let count = candles.count

    let targetLabelCount: Int

    switch count {

    case 1...20:
        targetLabelCount = 5

    case 21...50:
        targetLabelCount = 6

    case 51...100:
        targetLabelCount = 7

    case 101...200:
        targetLabelCount = 6

    default:
        targetLabelCount = 5
    }

    let step: Int

    if count <= targetLabelCount {

        step = 1

    } else {

        step =
            max(
                1,
                Int(
                    ceil(
                        Double(count - 1) /
                        Double(targetLabelCount - 1)
                    )
                )
            )
    }

    var index = 0

    while index < count {

        let x =
            coordinateSystem.x(
                forVisibleIndex: index
            )

        let date =
            dateFormatter.string(
                from: candles[index].date
            )

        let isFirst = index == 0
        let isLast = index == count - 1

        drawDate(
            date,
            x: x,
            chartRect: chartRect,
            attributes: attributes,
            alignRight: isLast,
            centered: !isFirst && !isLast
        )

        index += step
    }

    if (count - 1) % step != 0,
       count > 1 {

        let lastIndex = count - 1

        let x =
            coordinateSystem.x(
                forVisibleIndex: lastIndex
            )

        let date =
            dateFormatter.string(
                from: candles[lastIndex].date
            )

        drawDate(
            date,
            x: x,
            chartRect: chartRect,
            attributes: attributes,
            alignRight: true
        )
    }
}

private func drawDate(
    _ text: String,
    x: CGFloat,
    chartRect: CGRect,
    attributes: [NSAttributedString.Key: Any],
    alignRight: Bool = false,
    centered: Bool = false
) {

    let string = text as NSString

    let size =
        string.size(
            withAttributes: attributes
        )

    var drawX = x

    if alignRight {

        drawX -= size.width
    }

    if centered {

        drawX -= size.width / 2
    }

    string.draw(
        at: NSPoint(
            x: drawX,
            y: chartRect.minY - size.height - 8
        ),
        withAttributes: attributes
    )
}


}

