import Foundation

final class WeeklyCandlestickBuilder {

    static func build(from dailyCandles: [Candlestick]) -> [Candlestick] {

        guard !dailyCandles.isEmpty else { return [] }

        let calendar = Calendar(identifier: .gregorian)

        var grouped: [String: [Candlestick]] = [:]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-ww"

        for candle in dailyCandles {

            let weekKey = formatter.string(from: candle.date)

            grouped[weekKey, default: []].append(candle)
        }

        var weeklyCandles: [Candlestick] = []

        for (_, candles) in grouped {

            guard let firstDate = candles.first?.date else { continue }

            let weeklyAverage =
                candles
                    .map(\.weightedAverage)
                    .reduce(0, +)
                / Double(candles.count)

            let weeklyMax =
                candles
                    .map(\.max)
                    .max() ?? 0

            let weeklyMin =
                candles
                    .map(\.min)
                    .min() ?? 0

            weeklyCandles.append(
                Candlestick(
                    max: weeklyMax,
                    min: weeklyMin,
                    weightedAverage: weeklyAverage,
                    date: firstDate
                )
            )
        }

        return weeklyCandles.sorted {
            $0.date < $1.date
        }
    }
}
