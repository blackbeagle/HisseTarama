import Cocoa

final class DetailTabViewController: NSTabViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uygulama açıldığında Teknik sekme aktif olsun.
        selectedTabViewItemIndex = 0
    }

    // MARK: - Stock Selection

    func selectStock(symbol: String) {

        let normalizedSymbol =
            symbol
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        guard !normalizedSymbol.isEmpty else {
            return
        }

        // Tek gerçek kaynak:
        // AppSelectionState
        AppSelectionState.shared.setSymbol(
            normalizedSymbol
        )
    }

    // MARK: - Chart

    func refreshChart() {

        if let chartVC =
            children.compactMap({
                $0 as? ChartDetailViewController
            }).first {

            chartVC.refreshChart()
        }
    }
}
