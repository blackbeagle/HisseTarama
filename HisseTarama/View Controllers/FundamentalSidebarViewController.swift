import Cocoa

// MARK: - Selection

enum FundamentalSelection {

    case single(
        itemCode: String
    )

    case group(
        itemCodes: [String]
    )
}

// MARK: - Delegate

protocol FundamentalSidebarDelegate: AnyObject {

    func fundamentalSidebar(
        _ sidebar:
            FundamentalSidebarViewController,
        didSelect selection:
            FundamentalSelection
    )
}

// MARK: - Sidebar Node

final class FundamentalSidebarNode {

    let title: String

    let selection:
        FundamentalSelection?

    let isGroup: Bool

    var children:
        [FundamentalSidebarNode]

    init(
        title: String,
        selection:
            FundamentalSelection? = nil,
        children:
            [FundamentalSidebarNode] = [],
        isGroup: Bool = false
    ) {

        self.title = title

        self.selection = selection

        self.children = children

        self.isGroup = isGroup
    }
}

// MARK: - View Controller

final class FundamentalSidebarViewController:
    NSViewController {

    // MARK: - UI

    private let outlineView:
        NSOutlineView = {

            let outlineView =
                NSOutlineView()

            outlineView.translatesAutoresizingMaskIntoConstraints =
                false

            return outlineView
        }()

    private let scrollView:
        NSScrollView = {

            let scrollView =
                NSScrollView()

            scrollView.translatesAutoresizingMaskIntoConstraints =
                false

            scrollView.hasVerticalScroller = true

            scrollView.hasHorizontalScroller = false

            scrollView.autohidesScrollers = true

            return scrollView
        }()

    // MARK: - Delegate

    weak var delegate:
        FundamentalSidebarDelegate?

    // MARK: - Data

    private var nodes:
        [FundamentalSidebarNode] = []

    private(set) var currentStockSymbol:
        String?

    // MARK: - Lifecycle

    override func loadView() {

        view = NSView()

        view.translatesAutoresizingMaskIntoConstraints =
            false
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setupOutlineView()

        buildSidebarData()

        outlineView.reloadData()

        expandMainSections()
    }

    // MARK: - Setup

    private func setupOutlineView() {

        let column =
            NSTableColumn(
                identifier:
                    NSUserInterfaceItemIdentifier(
                        "FundamentalColumn"
                    )
            )

        column.title = "Finansal Kalemler"

        outlineView.addTableColumn(
            column
        )

        outlineView.outlineTableColumn =
            column

        outlineView.headerView = nil

        outlineView.delegate = self

        outlineView.dataSource = self

        outlineView.selectionHighlightStyle =
            .sourceList

        outlineView.rowSizeStyle =
            .default

        outlineView.intercellSpacing =
            NSSize(
                width: 0,
                height: 2
            )

        scrollView.documentView =
            outlineView

        view.addSubview(
            scrollView
        )

        NSLayoutConstraint.activate([

            scrollView.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor
            ),

            scrollView.trailingAnchor.constraint(
                equalTo:
                    view.trailingAnchor
            ),

            scrollView.topAnchor.constraint(
                equalTo:
                    view.topAnchor
            ),

            scrollView.bottomAnchor.constraint(
                equalTo:
                    view.bottomAnchor
            )
        ])
    }

    // MARK: - Data

    private func buildSidebarData() {

        nodes = [

            FundamentalSidebarNode(
                title: "Bilanço",
                children: [

                    FundamentalSidebarNode(
                        title:
                            "Nakit ve Nakit Benzerleri",
                        selection:
                            .single(
                                itemCode: "1AA"
                            )
                    ),

                    FundamentalSidebarNode(
                        title: "Stoklar",
                        selection:
                            .single(
                                itemCode: "1AF"
                            )
                    ),

                    FundamentalSidebarNode(
                        title: "Toplam Varlıklar",
                        selection:
                            .single(
                                itemCode: "1BL"
                            )
                    )
                ],
                isGroup: true
            ),

            FundamentalSidebarNode(
                title: "Gelir Tablosu",
                children: [

                    FundamentalSidebarNode(
                        title: "Satışlar",
                        selection:
                            .group(
                                itemCodes: [
                                    "3C",
                                    "3CA"
                                ]
                            )
                    ),

                    FundamentalSidebarNode(
                        title:
                            "Satış Gelirleri",
                        selection:
                            .single(
                                itemCode: "3C"
                            )
                    ),

                    FundamentalSidebarNode(
                        title:
                            "Satışların Maliyeti",
                        selection:
                            .single(
                                itemCode: "3CA"
                            )
                    ),

                    FundamentalSidebarNode(
                        title:
                            "Brüt Kâr (Zarar)",
                        selection:
                            .single(
                                itemCode: "3D"
                            )
                    )
                ],
                isGroup: true
            )
        ]
    }

    // MARK: - Expand

    private func expandMainSections() {

        for node in nodes {

            outlineView.expandItem(
                node
            )
        }
    }

    // MARK: - Stock

    func updateStock(
        symbol: String
    ) {

        currentStockSymbol = symbol

        print(
            "Temel sidebar hisse güncellendi: \(symbol)"
        )
    }
}

// MARK: - NSOutlineViewDataSource

extension FundamentalSidebarViewController:
    NSOutlineViewDataSource {

    func outlineView(
        _ outlineView: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {

        if let node =
            item as? FundamentalSidebarNode {

            return node.children.count
        }

        return nodes.count
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        isItemExpandable item: Any
    ) -> Bool {

        guard let node =
            item as? FundamentalSidebarNode
        else {
            return false
        }

        return !node.children.isEmpty
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        child index: Int,
        ofItem item: Any?
    ) -> Any {

        if let node =
            item as? FundamentalSidebarNode {

            return node.children[index]
        }

        return nodes[index]
    }
}

// MARK: - NSOutlineViewDelegate

extension FundamentalSidebarViewController:
    NSOutlineViewDelegate {

    func outlineView(
        _ outlineView: NSOutlineView,
        viewFor tableColumn: NSTableColumn?,
        item: Any
    ) -> NSView? {

        guard let node =
            item as? FundamentalSidebarNode
        else {
            return nil
        }

        let identifier =
            NSUserInterfaceItemIdentifier(
                "FundamentalSidebarCell"
            )

        let cell: NSTableCellView

        if let existing =
            outlineView.makeView(
                withIdentifier:
                    identifier,
                owner: self
            ) as? NSTableCellView {

            cell = existing

        } else {

            cell =
                NSTableCellView()

            cell.identifier =
                identifier

            let textField =
                NSTextField(
                    labelWithString: ""
                )

            textField.translatesAutoresizingMaskIntoConstraints =
                false

            cell.addSubview(
                textField
            )

            cell.textField =
                textField

            NSLayoutConstraint.activate([

                textField.leadingAnchor.constraint(
                    equalTo:
                        cell.leadingAnchor,
                    constant: 4
                ),

                textField.trailingAnchor.constraint(
                    equalTo:
                        cell.trailingAnchor,
                    constant: -4
                ),

                textField.centerYAnchor.constraint(
                    equalTo:
                        cell.centerYAnchor
                )
            ])
        }

        cell.textField?.stringValue =
            node.title

        if node.isGroup {

            cell.textField?.font =
                NSFont.boldSystemFont(
                    ofSize:
                        NSFont.systemFontSize
                )

        } else {

            cell.textField?.font =
                NSFont.systemFont(
                    ofSize:
                        NSFont.systemFontSize
                )
        }

        return cell
    }

    func outlineViewSelectionDidChange(
        _ notification: Notification
    ) {

        let row =
            outlineView.selectedRow

        guard row >= 0 else {
            return
        }

        let item =
            outlineView.item(
                atRow: row
            )

        guard let node =
            item as? FundamentalSidebarNode
        else {
            return
        }

        guard let selection =
            node.selection
        else {
            return
        }

        delegate?.fundamentalSidebar(
            self,
            didSelect: selection
        )
    }
}
