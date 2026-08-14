import Foundation

struct Candlestick {

    // MARK: - Common

    let date: Date

    // MARK: - TRY Values

    /// Günlük/haftalık maksimum fiyat
    let max: Double

    /// Günlük/haftalık minimum fiyat
    let min: Double

    /// Ağırlıklı ortalama fiyat
    let weightedAverage: Double

    // MARK: - USD Values

    /// USD bazlı maksimum fiyat
    let usdMax: Double?

    /// USD bazlı minimum fiyat
    let usdMin: Double?

    /// USD bazlı ağırlıklı ortalama fiyat
    let usdWeightedAverage: Double?

    // MARK: - Initializer

    init(
        max: Double,
        min: Double,
        weightedAverage: Double,
        date: Date = Date(),
        usdMax: Double? = nil,
        usdMin: Double? = nil,
        usdWeightedAverage: Double? = nil
    ) {

        self.max = max
        self.min = min
        self.weightedAverage = weightedAverage

        self.date = date

        self.usdMax = usdMax
        self.usdMin = usdMin
        self.usdWeightedAverage = usdWeightedAverage
    }
}
