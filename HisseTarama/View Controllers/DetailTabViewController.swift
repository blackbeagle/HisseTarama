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

        // -------------------------------------------------
        // Teknik
        // -------------------------------------------------

        if let chartVC =
            children.compactMap({
                $0 as? ChartDetailViewController
            }).first {

            chartVC.selectStock(
                symbol: normalizedSymbol
            )
        }

        // -------------------------------------------------
        // Temel
        // -------------------------------------------------

        if let fundamentalsVC =
            children.compactMap({
                $0 as? FundamentalsViewController
            }).first {

            fundamentalsVC.selectStock(
                symbol: normalizedSymbol
            )
        }

        // -------------------------------------------------
        // Dashboard
        // -------------------------------------------------

        if let dashboardVC =
            children.compactMap({
                $0 as? DashboardViewController
            }).first {

            dashboardVC.selectStock(
                symbol: normalizedSymbol
            )
        }
    }
    
    
    func refreshChart() {

        if let chartVC =
            children.compactMap({
                $0 as? ChartDetailViewController
            }).first {

            chartVC.refreshChart()
        }
    }
}
