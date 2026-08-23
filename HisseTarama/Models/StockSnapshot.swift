import Foundation

struct StockSnapshot {

    // MARK: - Financial Data

    let periods: [FinancialPeriod]

    let currency: StockCurrency

    let items: [String: FinancialStatementItem]

    // MARK: - Init

    init(
        periods: [FinancialPeriod] = [],
        currency: StockCurrency = .tryCurrency,
        items: [String: FinancialStatementItem] = [:]
    ) {
        self.periods = periods
        self.currency = currency
        self.items = items
    }
}
