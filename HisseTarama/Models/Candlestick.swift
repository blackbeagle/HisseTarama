import Foundation

struct Candlestick {

    // MARK: - Common

    let date: Date

    /// TRY işlem hacmi.
    ///
    /// Günlük mumda günlük TRY işlem hacmini,
    /// haftalık mumda haftalık toplam TRY işlem hacmini temsil eder.
    let volume: Double

    /// USD işlem hacmi.
    ///
    /// Günlük mumda günlük USD işlem hacmini,
    /// haftalık mumda haftalık toplam USD işlem hacmini temsil eder.
    let usdVolume: Double

    // MARK: - TRY Values

    /// Günlük/haftalık maksimum fiyat
    let max: Double

    /// Günlük/haftalık minimum fiyat
    let min: Double

    /// TRY bazlı ağırlıklı ortalama fiyat
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
        volume: Double,
        usdVolume: Double,
        usdMax: Double? = nil,
        usdMin: Double? = nil,
        usdWeightedAverage: Double? = nil
    ) {
        self.max = max
        self.min = min
        self.weightedAverage = weightedAverage
        self.date = date
        self.volume = volume
        self.usdVolume = usdVolume
        self.usdMax = usdMax
        self.usdMin = usdMin
        self.usdWeightedAverage = usdWeightedAverage
    }
}




