import Foundation

struct StockSnapshot {

    let stock: Stock

    let priceHistory: [Candlestick]

    let financials: FinancialStatements

    init(
        stock: Stock,
        priceHistory: [Candlestick] = [],
        financials: FinancialStatements = FinancialStatements()
    ) {
        self.stock = stock
        self.priceHistory = priceHistory
        self.financials = financials
    }
}
