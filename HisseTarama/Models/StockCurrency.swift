import Foundation

enum StockCurrency {
    case tryCurrency
    case usd

    var apiValue: String {
        switch self {
        case .tryCurrency:
            return "TRY"

        case .usd:
            return "USD"
        }
    }
}
