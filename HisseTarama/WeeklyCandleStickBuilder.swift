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
            // Haftalık TRY Max
            // -------------------------------------------------
            //
            // O hafta içerisindeki tüm günlük TRY Max
            // değerlerinin en büyüğü haftalık Max değeridir.
            //

            let weeklyMax =
                sortedCandles
                    .map(\.max)
                    .max() ?? 0

            // -------------------------------------------------
            // Haftalık TRY Min
            // -------------------------------------------------
            //
            // O hafta içerisindeki tüm günlük TRY Min
            // değerlerinin en küçüğü haftalık Min değeridir.
            //

            let weeklyMin =
                sortedCandles
                    .map(\.min)
                    .min() ?? 0

            // -------------------------------------------------
            // Haftalık USD Max
            // -------------------------------------------------
            //
            // USD verisi bulunan günlük barlar içerisindeki
            // en yüksek USD Max değeri haftalık USD Max'tir.
            //

            let weeklyUSDMax =
                sortedCandles
                    .compactMap(\.usdMax)
                    .max()

            // -------------------------------------------------
            // Haftalık USD Min
            // -------------------------------------------------
            //
            // USD verisi bulunan günlük barlar içerisindeki
            // en düşük USD Min değeri haftalık USD Min'dir.
            //

            let weeklyUSDMin =
                sortedCandles
                    .compactMap(\.usdMin)
                    .min()

            // -------------------------------------------------
            // Haftalık TRY Hacim
            // -------------------------------------------------
            //
            // Haftadaki günlük TRY işlem hacimlerinin toplamıdır.
            //

            let weeklyVolume =
                sortedCandles
                    .map(\.volume)
                    .reduce(0, +)

            // -------------------------------------------------
            // Haftalık USD Hacim
            // -------------------------------------------------
            //
            // Haftadaki günlük USD işlem hacimlerinin toplamıdır.
            //

            let weeklyUSDVolume =
                sortedCandles
                    .map(\.usdVolume)
                    .reduce(0, +)

            // -------------------------------------------------
            // Haftalık TRY AOF
            // -------------------------------------------------
            //
            // Günlük TRY AOF değerlerini TRY işlem hacimleri
            // ile ağırlıklandırıyoruz.
            //
            // Σ(TRY AOF × TRY Hacim)
            // -----------------------
            //       Σ TRY Hacim
            //

            let weeklyAverage: Double

            if weeklyVolume > 0 {

                let weightedSum =
                    sortedCandles.reduce(0) {
                        $0 + (
                            $1.weightedAverage
                            * $1.volume
                        )
                    }

                weeklyAverage =
                    weightedSum / weeklyVolume

            } else {

                // Hacim verisi bulunmuyorsa güvenli fallback:
                // günlük TRY AOF değerlerinin aritmetik ortalaması.

                weeklyAverage =
                    sortedCandles
                        .map(\.weightedAverage)
                        .reduce(0, +)
                    / Double(sortedCandles.count)
            }

            // -------------------------------------------------
            // Haftalık USD AOF
            // -------------------------------------------------
            //
            // USD AOF ve USD hacmi bulunan günlük barlar
            // kullanılır.
            //
            // Σ(USD AOF × USD Hacim)
            // -----------------------
            //       Σ USD Hacim
            //

            let usdCandles =
                sortedCandles.filter {
                    $0.usdWeightedAverage != nil &&
                    $0.usdVolume > 0
                }

            let weeklyUSDAverage: Double?

            let usdTotalVolume =
                usdCandles
                    .map(\.usdVolume)
                    .reduce(0, +)

            if usdTotalVolume > 0 {

                let usdWeightedSum =
                    usdCandles.reduce(0) {
                        $0 + (
                            ($1.usdWeightedAverage ?? 0)
                            * $1.usdVolume
                        )
                    }

                weeklyUSDAverage =
                    usdWeightedSum / usdTotalVolume

            } else {

                // USD hacmi yoksa USD AOF üretmiyoruz.
                weeklyUSDAverage = nil
            }

            // -------------------------------------------------
            // Haftalık tarih
            // -------------------------------------------------
            //
            // Grafikte haftayı temsil edecek tarih olarak
            // o haftanın ilk işlem gününü kullanıyoruz.
            //

            let firstTradingDay =
                sortedCandles.first?.date ?? weekStart

            // -------------------------------------------------
            // Haftalık Candlestick
            // -------------------------------------------------

            weeklyCandles.append(
                Candlestick(
                    max: weeklyMax,
                    min: weeklyMin,
                    weightedAverage: weeklyAverage,
                    date: firstTradingDay,
                    volume: weeklyVolume,
                    usdVolume: weeklyUSDVolume,
                    usdMax: weeklyUSDMax,
                    usdMin: weeklyUSDMin,
                    usdWeightedAverage: weeklyUSDAverage
                )
            )
        }

        // Haftalık barları kronolojik sıraya koy.

        return weeklyCandles.sorted {
            $0.date < $1.date
        }
    }
}

