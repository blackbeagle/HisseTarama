import Foundation

final class SidebarViewModel {

    // MARK: - App State

    private let appState = AppStockState.shared

    // MARK: - Watchlists

    var watchlists: [Watchlist] {
        appState.watchlists
    }

    // MARK: - Scans

    var scans: [Scan] {
        appState.scans
    }

    // MARK: - Scan Results

    var scanResults: [ScanResult] {
        appState.scanResults
    }
}
