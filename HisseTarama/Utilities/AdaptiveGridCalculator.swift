import Foundation

final class AdaptiveGridCalculator {

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
}
