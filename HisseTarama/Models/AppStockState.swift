import Foundation

final class AppStockState {

    static let shared = AppStockState()

    private init() {}

    // MARK: - Selected Stock

    private(set) var selectedStock: Stock?

    func selectStock(_ stock: Stock) {
        selectedStock = stock
    }

    func clearSelectedStock() {
        selectedStock = nil
    }

    // MARK: - Watchlists

    private(set) var watchlists: [Watchlist] = [

        Watchlist(
            name: "Takip Listem",
            stocks: [
                Stock(symbol: "SISE", name: "Şişecam"),
                Stock(symbol: "PGSUS", name: "Pegasus"),
                Stock(symbol: "THYAO", name: "Türk Hava Yolları"),
                Stock(symbol: "SAHOL", name: "Sabancı Holding"),
                Stock(symbol: "KCHOL", name: "Koç Holding"),
                Stock(symbol: "TCELL", name: "Turkcell"),
                Stock(symbol: "TTKOM", name: "Türk Telekom"),
                Stock(symbol: "ISCTR", name: "İş Bankası C"),
                Stock(symbol: "AKBNK", name: "Akbank"),
                Stock(symbol: "YKBNK", name: "Yapı Kredi"),
                Stock(symbol: "GARAN", name: "Garanti BBVA")
            ]
        )
    ]

    // MARK: - Scans

    private(set) var scans: [Scan] = []

    // MARK: - Scan Results

    private(set) var scanResults: [ScanResult] = []

    // MARK: - Watchlist

    func addWatchlist(_ watchlist: Watchlist) {
        watchlists.append(watchlist)
    }

    // MARK: - Scan

    func addScan(_ scan: Scan) {
        scans.append(scan)
    }

    // MARK: - Scan Result

    func setScanResults(_ results: [ScanResult]) {

        let scanIDs = Set(
            results.map { $0.scanID }
        )

        scanResults.removeAll {
            scanIDs.contains($0.scanID)
        }

        scanResults.append(contentsOf: results)
    }
}
