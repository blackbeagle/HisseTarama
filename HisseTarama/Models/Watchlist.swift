
import Foundation

struct Watchlist: Identifiable {

    let id: UUID
    var name: String
    var stocks: [Stock]

    init(
        id: UUID = UUID(),
        name: String,
        stocks: [Stock] = []
    ) {
        self.id = id
        self.name = name
        self.stocks = stocks
    }

    mutating func addStock(
        _ stock: Stock
    ) {
        guard !stocks.contains(stock) else {
            return
        }

        stocks.append(stock)
    }

    mutating func removeStock(
        _ stock: Stock
    ) {
        stocks.removeAll {
            $0 == stock
        }
    }

    func contains(
        _ stock: Stock
    ) -> Bool {
        stocks.contains(stock)
    }
}
