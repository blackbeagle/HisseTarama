import Foundation

struct Candlestick {
    let date: Date
    let max: Double
    let min: Double
    let weightedAverage: Double  // ağırlıklı ortalama fiyat
    
    init(max: Double, min: Double, weightedAverage: Double, date: Date = Date()) {
        self.max = max
        self.min = min
        self.weightedAverage = weightedAverage
        self.date = date
    }
}
