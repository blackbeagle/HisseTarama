import Foundation

struct Stock: Identifiable, Hashable {

    let id: String
    let symbol: String
    let name: String?

    init(
        symbol: String,
        name: String? = nil
    ) {
        self.id = symbol
        self.symbol = symbol
        self.name = name
    }
}
