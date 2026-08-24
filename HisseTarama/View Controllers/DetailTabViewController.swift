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
        // Global State
        // -------------------------------------------------

        AppSelectionState.shared.setSymbol(
            normalizedSymbol
        )

        // -------------------------------------------------
        // Temel
        // -------------------------------------------------

        for child in children {

            if let fundamentalsVC =
                child as? FundamentalsViewController {

                fundamentalsVC.selectStock(
                    symbol: normalizedSymbol
                )

                break
            }
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
