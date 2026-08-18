import Foundation

enum SidebarItemType {

    case watchlist
    case watchlistStock

    case scans
    case scan
    case scanResult
}

struct SidebarItem {

    let title: String
    let type: SidebarItemType

    let stock: Stock?
    let scan: Scan?

    let children: [SidebarItem]?

    init(
        title: String,
        type: SidebarItemType,
        stock: Stock? = nil,
        scan: Scan? = nil,
        children: [SidebarItem]? = nil
    ) {
        self.title = title
        self.type = type
        self.stock = stock
        self.scan = scan
        self.children = children
    }

    var isGroup: Bool {
        guard let children = children else {
            return false
        }

        return !children.isEmpty
    }
}
