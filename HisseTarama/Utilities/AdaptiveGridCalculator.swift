
import Foundation

final class AdaptiveGridCalculator {

    // MARK: - Horizontal Grid

    func horizontalGridCount(
        visibleBars: Int
    ) -> Int {

        switch visibleBars {

        case 0...40:
            return 8

        case 41...80:
            return 7

        case 81...150:
            return 6

        case 151...250:
            return 5

        default:
            return 4
        }
    }

    // MARK: - Vertical Grid

    func verticalStep(
        visibleBars: Int
    ) -> Int {

        switch visibleBars {

        case 0...25:
            return 5

        case 26...60:
            return 10

        case 61...120:
            return 20

        case 121...200:
            return 25

        default:
            return 50
        }
    }

    // MARK: - Price Grid

    func priceStep(
        minPrice: Double,
        maxPrice: Double,
        targetLines: Int
    ) -> Double {

        guard
            maxPrice > minPrice,
            targetLines > 0
        else {
            return 1
        }

        let range = maxPrice - minPrice

        let roughStep =
            range / Double(targetLines)

        guard roughStep > 0 else {
            return 1
        }

        let magnitude =
            pow(
                10,
                floor(log10(roughStep))
            )

        let normalized =
            roughStep / magnitude

        let niceNormalized: Double

        if normalized <= 1 {
            niceNormalized = 1

        } else if normalized <= 2 {
            niceNormalized = 2

        } else if normalized <= 5 {
            niceNormalized = 5

        } else {
            niceNormalized = 10
        }

        return niceNormalized * magnitude
    }

    // MARK: - Price Levels

    func priceLevels(
        minPrice: Double,
        maxPrice: Double,
        targetLines: Int
    ) -> [Double] {

        guard
            maxPrice > minPrice,
            targetLines > 0
        else {
            return []
        }

        let step =
            priceStep(
                minPrice: minPrice,
                maxPrice: maxPrice,
                targetLines: targetLines
            )

        guard step > 0 else {
            return []
        }

        let first =
            ceil(minPrice / step) * step

        var levels: [Double] = []

        var price = first

        while price <= maxPrice {

            levels.append(price)

            price += step
        }

        return levels
    }
}



