import Foundation

enum AppCurrency {

    case tryCurrency
    case usd

    var stockCurrency: StockCurrency {
        switch self {
        case .tryCurrency:
            return .tryCurrency

        case .usd:
            return .usd
        }
    }

    var title: String {
        switch self {
        case .tryCurrency:
            return "TRY"

        case .usd:
            return "USD"
        }
    }
}

final class AppSelectionState {

    static let shared = AppSelectionState()

    private init() {}

    // MARK: - Current Selection

    private(set) var selectedSymbol: String = ""
    private(set) var selectedCurrency: AppCurrency = .tryCurrency

    // MARK: - Notifications

    static let symbolDidChange =
        Notification.Name(
            "AppSelectionState.symbolDidChange"
        )

    static let currencyDidChange =
        Notification.Name(
            "AppSelectionState.currencyDidChange"
        )

    // MARK: - Symbol

    func setSymbol(_ symbol: String) {

        let normalizedSymbol =
            symbol
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        guard !normalizedSymbol.isEmpty else {
            return
        }

        guard normalizedSymbol != selectedSymbol else {
            return
        }

        selectedSymbol = normalizedSymbol

        NotificationCenter.default.post(
            name: Self.symbolDidChange,
            object: self
        )
    }

    // MARK: - Currency

    func setCurrency(_ currency: AppCurrency) {

        guard currency != selectedCurrency else {
            return
        }

        selectedCurrency = currency

        NotificationCenter.default.post(
            name: Self.currencyDidChange,
            object: self
        )
    }
}
