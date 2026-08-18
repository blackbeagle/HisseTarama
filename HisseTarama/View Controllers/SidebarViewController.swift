import Cocoa

final class SidebarViewController: NSViewController {

    // MARK: - Outlets

    @IBOutlet weak var outlineView: NSOutlineView!

    // MARK: - Delegate

    weak var selectionDelegate: SidebarSelectionDelegate?

    // MARK: - View Model

    private let viewModel = SidebarViewModel()

    // MARK: - Items

    private var items: [SidebarItem] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureOutlineView()
        rebuildItems()
    }

    // MARK: - Setup

    private func configureOutlineView() {

        outlineView.dataSource = self
        outlineView.delegate = self

        outlineView.allowsEmptySelection = false
        outlineView.allowsMultipleSelection = false

        outlineView.selectionHighlightStyle = .sourceList
    }

    // MARK: - Build Sidebar

    private func rebuildItems() {

        var newItems: [SidebarItem] = []

        // -------------------------------------------------
        // Takip Listem
        // -------------------------------------------------

        for watchlist in viewModel.watchlists {

            let stockItems = watchlist.stocks.map { stock in

                SidebarItem(
                    title: stock.symbol,
                    type: .watchlistStock,
                    stock: stock
                )
            }

            newItems.append(
                SidebarItem(
                    title: watchlist.name,
                    type: .watchlist,
                    children: stockItems
                )
            )
        }

        // -------------------------------------------------
        // Taramalar
        // -------------------------------------------------

        let scanItems = viewModel.scans.map { scan in

            SidebarItem(
                title: scan.name,
                type: .scan,
                scan: scan
            )
        }

        newItems.append(
            SidebarItem(
                title: "Taramalar",
                type: .scans,
                children: scanItems
            )
        )

        items = newItems

        outlineView.reloadData()

        DispatchQueue.main.async { [weak self] in

            guard let self = self else {
                return
            }

            self.outlineView.expandItem(
                nil,
                expandChildren: true
            )
        }
        
    }
}

extension SidebarViewController: NSOutlineViewDataSource {

    func outlineView(
        _ outlineView: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {

        if let sidebarItem = item as? SidebarItem {
            return sidebarItem.children?.count ?? 0
        }

        return items.count
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        child index: Int,
        ofItem item: Any?
    ) -> Any {

        if let sidebarItem = item as? SidebarItem {
            return sidebarItem.children![index]
        }

        return items[index]
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        isItemExpandable item: Any
    ) -> Bool {

        guard let sidebarItem = item as? SidebarItem else {
            return false
        }

        return sidebarItem.isGroup
    }
}


extension SidebarViewController: NSOutlineViewDelegate {

    func outlineView(
        _ outlineView: NSOutlineView,
        viewFor tableColumn: NSTableColumn?,
        item: Any
    ) -> NSView? {

        guard
            let sidebarItem = item as? SidebarItem,
            let cell =
                outlineView.makeView(
                    withIdentifier:
                        NSUserInterfaceItemIdentifier(
                            "DataCell"
                        ),
                    owner: self
                ) as? NSTableCellView
        else {
            return nil
        }

        cell.textField?.stringValue =
            sidebarItem.title

        return cell
    }

    func outlineViewSelectionDidChange(
        _ notification: Notification
    ) {

        let row = outlineView.selectedRow

        guard row >= 0 else {
            return
        }

        guard
            let item =
                outlineView.item(
                    atRow: row
                ) as? SidebarItem
        else {
            return
        }

        // Sadece hisse seçilebilir.
        guard
            let stock = item.stock
        else {
            return
        }

        selectionDelegate?.sidebar(
            self,
            didSelect: .stock(
                symbol: stock.symbol
            )
        )
    }
}
