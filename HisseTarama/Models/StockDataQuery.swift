import Foundation

struct StockDataQuery {
    
    // MARK: - Financial Period
    
    /// Kullanıcının belirlediği son raporlanan finansal dönem.
    let lastFinancialPeriod: FinancialPeriod
    
    /// Geriye doğru alınacak çeyrek sayısı.
    /// nil ise servis kendi varsayılan değerini kullanabilir.
    let financialQuarterCount: Int?
    
    // MARK: - Currency
    
    /// Fiyat ve finansal veriler için kullanılacak para birimi.
    let currency: StockCurrency
    
    // MARK: - Init
    
    init(
        lastFinancialPeriod: FinancialPeriod,
        financialQuarterCount: Int? = 10,
        //currency: StockCurrency = .tryCurrency
        currency: StockCurrency = .usd
    ) {
        self.lastFinancialPeriod = lastFinancialPeriod
        self.financialQuarterCount = financialQuarterCount
        self.currency = currency
    }
}
