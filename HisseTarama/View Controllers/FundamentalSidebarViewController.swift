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

        self.selection =
            selection

        self.children =
            children

        self.isGroup =
            isGroup
    }
}

// MARK: - View Controller

final class FundamentalSidebarViewController:
    NSViewController {

    // MARK: - UI

    private let modeToggle: NSSegmentedControl = {

        let control =
            NSSegmentedControl(
                labels:
                    ["Kalem", "Grup"],
                trackingMode:
                    .selectOne,
                target:
                    nil,
                action:
                    nil
            )

        control.selectedSegment =
            0

        control.segmentDistribution =
            .fillEqually

        control.translatesAutoresizingMaskIntoConstraints =
            false

        return control
    }()

    private let searchField: NSSearchField = {

        let field =
            NSSearchField()

        field.placeholderString =
            "Kalem Ara"

        field.sendsSearchStringImmediately =
            true

        field.translatesAutoresizingMaskIntoConstraints =
            false

        return field
    }()

    private let modeSeparator: NSBox = {

        let box =
            NSBox()

        box.boxType =
            .separator

        box.translatesAutoresizingMaskIntoConstraints =
            false

        return box
    }()

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

        scrollView.hasVerticalScroller =
            true

        scrollView.hasHorizontalScroller =
            false

        scrollView.autohidesScrollers =
            true

        return scrollView
    }()

    // MARK: - Delegate

    weak var delegate:
        FundamentalSidebarDelegate?

    // MARK: - Data

    private var nodes:
        [FundamentalSidebarNode] = []

    private var allFinancialItems:
        [FinancialStatementItem] = []

    private(set) var currentStockSymbol:
        String?

    /// Kullanıcının en son seçtiği finansal kalem.
    ///
    /// Mod değişse bile korunur.
    private var lastSelectedItemCode:
        String?

    // MARK: - Lifecycle

    override func loadView() {

        view =
            NSView()

        view.translatesAutoresizingMaskIntoConstraints =
            false
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setupModeToggle()

        setupSearchField()

        setupOutlineView()
    }

    // MARK: - Mode Toggle

    private func setupModeToggle() {

        modeToggle.target =
            self

        modeToggle.action =
            #selector(
                modeToggleChanged(_:)
            )

        view.addSubview(
            modeToggle
        )

        NSLayoutConstraint.activate([

            modeToggle.topAnchor.constraint(
                equalTo:
                    view.topAnchor,
                constant:
                    12
            ),

            modeToggle.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor,
                constant:
                    12
            ),

            modeToggle.trailingAnchor.constraint(
                equalTo:
                    view.trailingAnchor,
                constant:
                    -12
            ),

            modeToggle.heightAnchor.constraint(
                equalToConstant:
                    28
            )
        ])
    }

    // MARK: - Search Field

    private func setupSearchField() {

        searchField.target =
            self

        searchField.action =
            #selector(
                searchFieldChanged(_:)
            )

        view.addSubview(
            searchField
        )

        NSLayoutConstraint.activate([

            searchField.topAnchor.constraint(
                equalTo:
                    modeToggle.bottomAnchor,
                constant:
                    8
            ),

            searchField.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor,
                constant:
                    12
            ),

            searchField.trailingAnchor.constraint(
                equalTo:
                    view.trailingAnchor,
                constant:
                    -12
            ),

            searchField.heightAnchor.constraint(
                equalToConstant:
                    24
            )
        ])
    }

    @objc private func searchFieldChanged(
        _ sender:
            NSSearchField
    ) {

        filterFinancialItems(
            searchText:
                sender.stringValue
        )
    }

    // MARK: - Search / Filtering

    private func filterFinancialItems(
        searchText:
            String
    ) {

        let trimmedText =
            searchText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        if trimmedText.isEmpty {

            rebuildNodes(
                from:
                    allFinancialItems
            )

            return
        }

        let filteredItems =
            allFinancialItems.filter {

                let title =
                    $0.titleTR.isEmpty
                        ? $0.itemCode
                        : $0.titleTR

                return title.range(
                    of:
                        trimmedText,
                    options:
                        [
                            .caseInsensitive,
                            .diacriticInsensitive
                        ],
                    locale:
                        Locale(identifier: "tr_TR")
                ) != nil
            }

        rebuildNodes(
            from:
                filteredItems
        )
    }

    private func rebuildNodes(
        from items:
            [FinancialStatementItem]
    ) {

        nodes.removeAll(
            keepingCapacity:
                true
        )

        let sortedItems =
            items.sorted {

                $0.itemCode.localizedStandardCompare(
                    $1.itemCode
                ) ==
                    .orderedAscending
            }

        for item in sortedItems {

            let title =
                item.titleTR.isEmpty
                    ? item.itemCode
                    : item.titleTR

            let node =
                FundamentalSidebarNode(
                    title:
                        title,

                    selection:
                        .single(
                            itemCode:
                                item.itemCode
                        ),

                    isGroup:
                        false
                )

            nodes.append(
                node
            )
        }

        outlineView.reloadData()
    }

    // MARK: - Mode Change

    @objc private func modeToggleChanged(
        _ sender:
            NSSegmentedControl
    ) {

        switch sender.selectedSegment {

        case 0:

            switchToItemMode()

        case 1:

            switchToGroupMode()

        default:

            break
        }
    }

    // MARK: - Item Mode

    private func switchToItemMode() {

        print(
            "TEMEL SIDEBAR MODU: KALEM"
        )

        guard
            let itemCode =
                lastSelectedItemCode
        else {
            return
        }

        print(
            "Son seçilen kalem korunuyor: \(itemCode)"
        )

        delegate?.fundamentalSidebar(
            self,
            didSelect:
                .single(
                    itemCode:
                        itemCode
                )
        )
    }

    // MARK: - Group Mode

    private func switchToGroupMode() {

        print(
            "TEMEL SIDEBAR MODU: GRUP"
        )

        guard
            let itemCode =
                lastSelectedItemCode
        else {

            showNoSelectedItemAlert()

            modeToggle.selectedSegment =
                0

            return
        }

        guard
            let group =
                FundamentalGroup.group(
                    containing:
                        itemCode
                )
        else {

            showNoGroupAlert(
                itemCode:
                    itemCode
            )

            modeToggle.selectedSegment =
                0

            return
        }

        print(
            "Grup bulundu: \(group.title)"
        )

        print(
            "Grup kalemleri: \(group.itemCodes)"
        )

        delegate?.fundamentalSidebar(
            self,
            didSelect:
                .group(
                    itemCodes:
                        group.itemCodes
                )
        )
    }

    // MARK: - Alerts

    private func showNoGroupAlert(
        itemCode:
            String
    ) {

        let alert =
            NSAlert()

        alert.messageText =
            "Bu finansal kalem bir gruba ait değil."

        alert.informativeText =
            """
            Seçili kalem grup şablonlarından herhangi birine \
            dahil olmadığı için Grup modu açılamadı.

            Kalem kodu: \(itemCode)
            """

        alert.alertStyle =
            .warning

        alert.addButton(
            withTitle:
                "Tamam"
        )

        alert.runModal()
    }

    private func showNoSelectedItemAlert() {

        let alert =
            NSAlert()

        alert.messageText =
            "Finansal kalem seçilmedi."

        alert.informativeText =
            "Grup modunu kullanabilmek için önce bir finansal kalem seçin."

        alert.alertStyle =
            .warning

        alert.addButton(
            withTitle:
                "Tamam"
        )

        alert.runModal()
    }

    // MARK: - Outline View Setup

    private func setupOutlineView() {

        let column =
            NSTableColumn(
                identifier:
                    NSUserInterfaceItemIdentifier(
                        "FundamentalColumn"
                    )
            )

        column.title =
            "Finansal Kalemler"

        outlineView.addTableColumn(
            column
        )

        outlineView.outlineTableColumn =
            column

        outlineView.headerView =
            nil

        outlineView.delegate =
            self

        outlineView.dataSource =
            self

        outlineView.selectionHighlightStyle =
            .sourceList

        outlineView.rowSizeStyle =
            .default

        // Her satırın yüksekliğini açıkça belirliyoruz.
        // Böylece metinler birbirine girmeyecek.
        outlineView.rowHeight =
            22

        outlineView.intercellSpacing =
            NSSize(
                width:
                    0,
                height:
                    0
            )

        scrollView.documentView =
            outlineView

        view.addSubview(
            modeSeparator
        )

        view.addSubview(
            scrollView
        )

        NSLayoutConstraint.activate([

            modeSeparator.topAnchor.constraint(
                equalTo:
                    searchField.bottomAnchor,
                constant:
                    8
            ),

            modeSeparator.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor
            ),

            modeSeparator.trailingAnchor.constraint(
                equalTo:
                    view.trailingAnchor
            ),

            modeSeparator.heightAnchor.constraint(
                equalToConstant:
                    1
            ),

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
                    modeSeparator.bottomAnchor,
                constant:
                    8
            ),

            scrollView.bottomAnchor.constraint(
                equalTo:
                    view.bottomAnchor
            )
        ])
    }

    // MARK: - Financial Items

    func updateFinancialItems(
        items:
            [FinancialStatementItem]
    ) {

        allFinancialItems =
            items

        rebuildNodes(
            from:
                items
        )

        print(
            "Fundamental sidebar güncellendi. Kalem sayısı: \(items.count)"
        )
    }

    func clearFinancialItems() {

        nodes.removeAll()

        allFinancialItems.removeAll()

        lastSelectedItemCode =
            nil

        searchField.stringValue =
            ""

        outlineView.deselectAll(
            nil
        )

        outlineView.reloadData()
    }

    // MARK: - Stock

    func updateStock(
        symbol:
            String
    ) {

        currentStockSymbol =
            symbol

        print(
            "Temel sidebar hisse güncellendi: \(symbol)"
        )
    }
}

// MARK: - NSOutlineViewDataSource / Delegate

extension FundamentalSidebarViewController:
    NSOutlineViewDataSource,
    NSOutlineViewDelegate {

    // MARK: Number Of Children

    func outlineView(
        _ outlineView:
            NSOutlineView,
        numberOfChildrenOfItem item:
            Any?
    ) -> Int {

        if let node =
            item as?
                FundamentalSidebarNode {

            return node.children.count
        }

        return nodes.count
    }

    // MARK: Expandable

    func outlineView(
        _ outlineView:
            NSOutlineView,
        isItemExpandable item:
            Any
    ) -> Bool {

        guard
            let node =
                item as?
                FundamentalSidebarNode
        else {
            return false
        }

        return !node.children.isEmpty
    }

    // MARK: Child

    func outlineView(
        _ outlineView:
            NSOutlineView,
        child index:
            Int,
        ofItem item:
            Any?
    ) -> Any {

        if let node =
            item as?
                FundamentalSidebarNode {

            return node.children[index]
        }

        return nodes[index]
    }

    // MARK: Cell View

    func outlineView(
        _ outlineView:
            NSOutlineView,
        viewFor tableColumn:
            NSTableColumn?,
        item:
            Any
    ) -> NSView? {

        guard
            let node =
                item as?
                FundamentalSidebarNode
        else {
            return nil
        }

        let identifier =
            NSUserInterfaceItemIdentifier(
                "FundamentalCell"
            )

        let cell =
            outlineView.makeView(
                withIdentifier:
                    identifier,
                owner:
                    self
            ) as?
                NSTableCellView
            ??
            NSTableCellView()

        cell.identifier =
            identifier

        // --------------------------------------------------
        // KRİTİK NOKTA:
        //
        // NSOutlineView hücreleri yeniden kullanır.
        // NSTextField oluşturduktan sonra bunu
        // cell.textField'e atıyoruz.
        //
        // Böylece aynı hücreye her kullanımda yeni
        // NSTextField eklenmez.
        // --------------------------------------------------

        let textField:
            NSTextField

        if let existingTextField =
            cell.textField {

            textField =
                existingTextField

        } else {

            textField =
                NSTextField(
                    labelWithString:
                        ""
                )

            textField.translatesAutoresizingMaskIntoConstraints =
                false

            // Çok önemli:
            cell.textField =
                textField

            cell.addSubview(
                textField
            )

            NSLayoutConstraint.activate([

                textField.leadingAnchor.constraint(
                    equalTo:
                        cell.leadingAnchor,
                    constant:
                        4
                ),

                textField.trailingAnchor.constraint(
                    equalTo:
                        cell.trailingAnchor,
                    constant:
                        -4
                ),

                textField.centerYAnchor.constraint(
                    equalTo:
                        cell.centerYAnchor
                ),

                textField.heightAnchor.constraint(
                    equalToConstant:
                        18
                )
            ])
        }

        // MARK: Text

        textField.stringValue =
            node.title

        textField.font =
            node.isGroup
                ? NSFont.systemFont(
                    ofSize:
                        13,
                    weight:
                        .semibold
                )
                : NSFont.systemFont(
                    ofSize:
                        13
                )

        // MARK: Single Line

        textField.usesSingleLineMode =
            true

        textField.maximumNumberOfLines =
            1

        textField.lineBreakMode =
            .byTruncatingTail

        textField.isEditable =
            false

        textField.isSelectable =
            false

        textField.drawsBackground =
            false

        textField.isBordered =
            false

        return cell
    }

    // MARK: Selection

    func outlineViewSelectionDidChange(
        _ notification:
            Notification
    ) {

        let row =
            outlineView.selectedRow

        guard row >= 0 else {
            return
        }

        guard
            let node =
                outlineView.item(
                    atRow:
                        row
                ) as?
                FundamentalSidebarNode
        else {
            return
        }

        guard
            let selection =
                node.selection
        else {
            return
        }

        switch selection {

        case .single(
            let itemCode
        ):

            lastSelectedItemCode =
                itemCode

            print(
                "SON SEÇİLEN FİNANSAL KALEM: \(itemCode)"
            )

            // KALEM MODU

            if modeToggle.selectedSegment == 0 {

                delegate?.fundamentalSidebar(
                    self,
                    didSelect:
                        .single(
                            itemCode:
                                itemCode
                        )
                )

                return
            }

            // GRUP MODU

            guard
                let group =
                    FundamentalGroup.group(
                        containing:
                            itemCode
                    )
            else {

                showNoGroupAlert(
                    itemCode:
                        itemCode
                )

                return
            }

            print(
                "GRUP MODU → \(group.title)"
            )

            delegate?.fundamentalSidebar(
                self,
                didSelect:
                    .group(
                        itemCodes:
                            group.itemCodes
                    )
            )

        case .group(
            let itemCodes
        ):

            delegate?.fundamentalSidebar(
                self,
                didSelect:
                    .group(
                        itemCodes:
                            itemCodes
                    )
            )
        }
    }
}
