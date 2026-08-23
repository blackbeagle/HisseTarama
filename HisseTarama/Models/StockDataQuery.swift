import Foundation

struct StockDataQuery {

    // MARK: - Financial Period

    /// nil ise yayınlanmış son bilanço otomatik keşfedilir.
    let lastFinancialPeriod: FinancialPeriod?

    /// nil ise tüm uygun dönemler yerine varsayılan 10 çeyrek alınır.
    let financialQuarterCount: Int?

    // MARK: - Currency

    let currency: StockCurrency

    // MARK: - Init

    init(
        lastFinancialPeriod: FinancialPeriod? = nil,
        financialQuarterCount: Int? = 10,
        currency: StockCurrency = .tryCurrency
    ) {
        self.lastFinancialPeriod =
            lastFinancialPeriod

        self.financialQuarterCount =
            financialQuarterCount

        self.currency =
            currency
    }
}
