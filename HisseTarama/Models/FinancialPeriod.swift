import Foundation

struct FinancialPeriod: Hashable {

    let year: Int
    let quarter: Int

    init(
        year: Int,
        quarter: Int
    ) {
        self.year = year
        self.quarter = quarter
    }

    var title: String {
        "\(year) Q\(quarter)"
    }
}
