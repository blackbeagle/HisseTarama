import Foundation

struct FinancialStatements {

    // MARK: - Periods

    /// Sorgulanan finansal dönemler.
    ///
    /// Her zaman en yeni dönemden eski döneme doğru tutulur.
    let periods: [FinancialPeriod]

    // MARK: - Currency

    let currency: StockCurrency

    // MARK: - Items

    /// Finansal tablo kalemleri.
    ///
    /// Key = itemCode
    let items: [String: FinancialStatementItem]

    // MARK: - Init

    init(
        periods: [FinancialPeriod],
        currency: StockCurrency,
        items: [String: FinancialStatementItem]
    ) {
        self.periods = periods
        self.currency = currency
        self.items = items
    }

    // MARK: - Item Access

    func item(
        code: String
    ) -> FinancialStatementItem? {

        items[code]
    }

    // MARK: - All Items

    var allItems: [FinancialStatementItem] {

        items.values.sorted {
            if $0.level != $1.level {
                return $0.level < $1.level
            }

            return $0.itemCode < $1.itemCode
        }
    }
}
