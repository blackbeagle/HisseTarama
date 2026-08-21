import Foundation

struct StockDataQuery {

    // MARK: - Financial Period

    /// Kullanıcı bir dönem verirse doğrudan kullanılır.
    /// nil ise servis yayınlanmış son bilanço dönemini otomatik keşfeder.
    let lastFinancialPeriod: FinancialPeriod?

    /// Geriye doğru alınacak çeyrek sayısı.
    /// nil ise varsayılan değer kullanılır.
    let financialQuarterCount: Int?

    // MARK: - Currency

    let currency: StockCurrency

    // MARK: - Init

    init(
        lastFinancialPeriod: FinancialPeriod? = nil,
        financialQuarterCount: Int? = 10,
        currency: StockCurrency = .tryCurrency
    ) {
        self.lastFinancialPeriod = lastFinancialPeriod
        self.financialQuarterCount = financialQuarterCount
        self.currency = currency
    }
}
