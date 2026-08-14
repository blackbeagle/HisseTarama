import Foundation

final class WeeklyCandlestickBuilder {

    static func build(
        from dailyCandles: [Candlestick]
    ) -> [Candlestick] {

        guard !dailyCandles.isEmpty else {
            return []
        }

        // ISO hafta takvimi:
        // Pazartesi haftanın ilk günü,
        // hafta numarası ve hafta yılı birlikte değerlendirilir.
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone.current

        // Her ISO haftayı ayrı bir grup olarak tutuyoruz.
        var grouped: [Date: [Candlestick]] = [:]

        for candle in dailyCandles {

            guard let weekInterval = calendar.dateInterval(
                of: .weekOfYear,
                for: candle.date
            ) else {
                continue
            }

            let weekStart = weekInterval.start

            grouped[weekStart, default: []].append(candle)
        }

        var weeklyCandles: [Candlestick] = []

        for (weekStart, candles) in grouped {

            guard !candles.isEmpty else {
                continue
            }

            // Günlük verileri tarih sırasına koy.
            let sortedCandles = candles.sorted {
                $0.date < $1.date
            }

            // -------------------------------------------------
            // Haftalık Max
            // -------------------------------------------------
            //
            // O hafta içerisindeki tüm günlük Max değerlerinin
            // en büyüğü gerçek haftalık Max değeridir.
            //
            let weeklyMax =
                sortedCandles
                    .map(\.max)
                    .max() ?? 0

            // -------------------------------------------------
            // Haftalık Min
            // -------------------------------------------------
            //
            // O hafta içerisindeki tüm günlük Min değerlerinin
            // en küçüğü gerçek haftalık Min değeridir.
            //
            let weeklyMin =
                sortedCandles
                    .map(\.min)
                    .min() ?? 0

            // -------------------------------------------------
            // Haftalık AOF
            // -------------------------------------------------
            //
            // Mevcut sistemdeki davranışı koruyoruz:
            // günlük AOF değerlerinin aritmetik ortalaması.
            //
            let weeklyAverage =
                sortedCandles
                    .map(\.weightedAverage)
                    .reduce(0, +)
                / Double(sortedCandles.count)

            // -------------------------------------------------
            // Haftalık tarih
            // -------------------------------------------------
            //
            // Grafikte haftayı temsil edecek tarih olarak
            // o haftanın ilk işlem gününü kullanıyoruz.
            //
            let firstTradingDay =
                sortedCandles.first?.date ?? weekStart

            weeklyCandles.append(
                Candlestick(
                    max: weeklyMax,
                    min: weeklyMin,
                    weightedAverage: weeklyAverage,
                    date: firstTradingDay
                )
            )
        }

        // Haftalık barları kronolojik sıraya koy.
        return weeklyCandles.sorted {
            $0.date < $1.date
        }
    }
}
