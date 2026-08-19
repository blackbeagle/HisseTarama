import Foundation

struct FinancialStatements {

    // MARK: - Constants

    static let defaultQuarterCount = 10

    // MARK: - Properties

    /// Kullanılacak finansal dönemler.
    /// En yeni dönemden eskiye doğru sıralanır.
    let periods: [FinancialPeriod]

    /// Finansal kalemler.
    ///
    /// Örnek:
    /// "Hasılat" -> dönem bazında değerler
    /// "Net Dönem Karı" -> dönem bazında değerler
    let items: [String: [FinancialPeriod: Double?]]

    // MARK: - Initialization

    init(
        periods: [FinancialPeriod] = [],
        items: [String: [FinancialPeriod: Double?]] = [:]
    ) {
        self.periods = periods
        self.items = items
    }

    // MARK: - Item Access

    /// Belirli bir finansal kalemin tüm dönemlerdeki değerlerini döndürür.
    ///
    /// Dönem sırası `periods` ile aynıdır.
    func values(
        for item: String
    ) -> [Double?] {

        guard let itemValues = items[item] else {
            return Array(
                repeating: nil,
                count: periods.count
            )
        }

        return periods.map { period in
            itemValues[period] ?? nil
        }
    }

    /// Belirli bir finansal kalemin belirli bir dönemdeki değerini döndürür.
    func value(
        for item: String,
        period: FinancialPeriod
    ) -> Double? {

        guard let itemValues = items[item] else {
            return nil
        }

        return itemValues[period] ?? nil
    }

    /// Finansal kalemin mevcut olup olmadığını kontrol eder.
    func contains(
        item: String
    ) -> Bool {

        items[item] != nil
    }
}
