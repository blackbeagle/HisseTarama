
import Cocoa

final class DetailTabViewController: NSTabViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uygulama açıldığında Teknik sekme aktif olsun.
        selectedTabViewItemIndex = 0

        setupDataFetchCallbacks()
    }
    // MARK: - Data Fetch Callbacks

    private func setupDataFetchCallbacks() {
        
        print("=== DETAIL CALLBACK SETUP ===")
        print("Child sayısı: \(children.count)")
        for child in children {
            print("Child: \(type(of: child))")
        }

        // Teknik veri sonucu
        if let chartVC = children.compactMap({
            $0 as? ChartDetailViewController
        }).first {

            chartVC.onDataFetchCompleted = {
                [weak self] symbol, success in

                self?.technicalDataDidFinish(
                    symbol: symbol,
                    success: success
                )
            }
        }

        // Temel veri sonucu
        if let fundamentalsVC = children.compactMap({
            $0 as? FundamentalsViewController
        }).first {

            fundamentalsVC.onDataFetchCompleted = {
                [weak self] symbol, success in

                self?.fundamentalDataDidFinish(
                    symbol: symbol,
                    success: success
                )
            }
        }
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

   
    // MARK: - Data Result

    /// Teknik veri işlemi tamamlandığında
    /// MainSplitViewController'a kadar sonucu iletir.
    func technicalDataDidFinish(
        symbol: String,
        success: Bool
    ) {
        var controller: NSViewController? = self

        while let current = controller {

            if let mainSplitVC =
                current as? MainSplitViewController {

                // SONUCU GERÇEKTEN MAIN SPLIT'E İLET
                mainSplitVC.technicalDataDidFinish(
                    symbol: symbol,
                    success: success
                )

                return
            }

            controller = current.parent
        }

        print(
            "HATA: MainSplitViewController bulunamadı - teknik veri sonucu"
        )
    }

    /// Temel veri işlemi tamamlandığında
    /// MainSplitViewController'a kadar sonucu iletir.
    func fundamentalDataDidFinish(
        symbol: String,
        success: Bool
    ) {
        var controller: NSViewController? = self

        while let current = controller {

            if let mainSplitVC =
                current as? MainSplitViewController {

                // SONUCU GERÇEKTEN MAIN SPLIT'E İLET
                mainSplitVC.fundamentalDataDidFinish(
                    symbol: symbol,
                    success: success
                )

                return
            }

            controller = current.parent
        }

        print(
            "HATA: MainSplitViewController bulunamadı - temel veri sonucu"
        )
    }
    


   
}


