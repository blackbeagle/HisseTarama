import Foundation

struct FinancialStatementItem: Hashable {

    // MARK: - Identity

    let itemCode: String

    // MARK: - Titles

    let titleTR: String
    let titleEN: String

    // MARK: - Hierarchy

    let level: Int

    // MARK: - Values

    let values: [FinancialPeriod: Double?]

    // MARK: - Init

    init(
        itemCode: String,
        titleTR: String,
        titleEN: String,
        level: Int,
        values: [FinancialPeriod: Double?] = [:]
    ) {
        self.itemCode = itemCode
        self.titleTR = titleTR
        self.titleEN = titleEN
        self.level = level
        self.values = values
    }

    // MARK: - Compatibility

    /// Finansal kalemin Türkçe görünen adı.
    var name: String {
        titleTR
    }

    /// Finansal kalemin kodu için kısa erişim.
    var code: String {
        itemCode
    }

    /// UI tarafında kullanılabilecek görünen başlık.
    var displayTitle: String {
        if !titleTR.isEmpty {
            return titleTR
        }

        if !titleEN.isEmpty {
            return titleEN
        }

        return itemCode
    }

    /// Belirli bir dönem için finansal değer.
    func value(
        for period: FinancialPeriod
    ) -> Double? {
        values[period] ?? nil
    }
}



