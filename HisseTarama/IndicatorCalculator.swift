import Foundation

class IndicatorCalculator {
    
    // SMA (Simple Moving Average) hesaplama
    // Parametreler: fiyatlar dizisi, periyot (örnek: 5, 10, 20, 50, 100, 200)
    static func calculateSMA(prices: [Double], period: Int) -> [Double?] {
        guard prices.count >= period else { return Array(repeating: nil, count: prices.count) }
        
        var smaValues: [Double?] = Array(repeating: nil, count: period - 1)
        
        for i in period...prices.count {
            let sum = prices[i-period..<i].reduce(0, +)
            let sma = sum / Double(period)
            smaValues.append(sma)
        }
        
        return smaValues
    }
    
    // Tüm fiyatları (ağırlıklı ortalama) bir diziden al
    static func getWeightedAveragePrices(from candlesticks: [Candlestick]) -> [Double] {
        return candlesticks.map { $0.weightedAverage }
    }
}
