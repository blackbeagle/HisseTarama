import Cocoa

// MARK: - Selection

enum FundamentalSelection {
    case single(itemCode: String)
    case group(itemCodes: [String])
}

// MARK: - Delegate

protocol FundamentalSidebarDelegate: AnyObject {
    func fundamentalSidebar(
        _ sidebar: FundamentalSidebarViewController,
        didSelect selection: FundamentalSelection
    )
}

// MARK: - Sidebar Node

final class FundamentalSidebarNode {

    let title: String

    let selection: FundamentalSelection?

    let isGroup: Bool

    var children: [FundamentalSidebarNode]

    init(
        title: String,
        selection: FundamentalSelection? = nil,
        children: [FundamentalSidebarNode] = [],
        isGroup: Bool = false
    ) {
        self.title = title
        self.selection = selection
        self.children = children
        self.isGroup = isGroup
    }
}

// MARK: - View Controller

final class FundamentalSidebarViewController: NSViewController {

    // MARK: - UI

    private let modeToggle: NSSegmentedControl = {

        let control = NSSegmentedControl(
            labels: [
                "Kalem",
                "Grup"
            ],
            trackingMode: .selectOne,
            target: nil,
            action: nil
        )

        control.selectedSegment = 0
        control.segmentDistribution = .fillEqually
        control.translatesAutoresizingMaskIntoConstraints = false

        return control
    }()

    private let searchField: NSSearchField = {

        let field = NSSearchField()

        field.placeholderString = "Kalem Ara"
        field.sendsSearchStringImmediately = true
        field.translatesAutoresizingMaskIntoConstraints = false

        return field
    }()

    private let modeSeparator: NSBox = {

        let box = NSBox()

        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false

        return box
    }()

    private let outlineView: NSOutlineView = {

        let outlineView = NSOutlineView()

        outlineView.translatesAutoresizingMaskIntoConstraints = false

        return outlineView
    }()

    private let scrollView: NSScrollView = {

        let scrollView = NSScrollView()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        return scrollView
    }()

    // MARK: - Delegate

    weak var delegate: FundamentalSidebarDelegate?

    // MARK: - Data

    private var nodes: [FundamentalSidebarNode] = []

    private var allFinancialItems: [FinancialStatementItem] = []

    private(set) var currentStockSymbol: String?

    private var lastSelectedItemCode: String?

    // Arama sırasında otomatik açılması gereken gruplar.
    private var groupsToExpandAfterReload: Set<String> = []

    // MARK: - Lifecycle

    override func loadView() {

        view = NSView()

        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setupModeToggle()
        setupSearchField()
        setupOutlineView()
    }

    // MARK: - Setup

    private func setupModeToggle() {

        modeToggle.target = self
        modeToggle.action = #selector(
            modeToggleChanged(_:)
        )

        view.addSubview(modeToggle)

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

    private func setupSearchField() {

        searchField.target = self
        searchField.action = #selector(
            searchFieldChanged(_:)
        )

        view.addSubview(searchField)

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

    private func setupOutlineView() {

        let column = NSTableColumn(
            identifier:
                NSUserInterfaceItemIdentifier(
                    "FundamentalColumn"
                )
        )

        column.title = "Finansal Kalemler"

        outlineView.addTableColumn(column)

        outlineView.outlineTableColumn = column

        outlineView.headerView = nil

        outlineView.delegate = self

        outlineView.dataSource = self

        outlineView.selectionHighlightStyle = .sourceList

        outlineView.rowSizeStyle = .default

        outlineView.rowHeight = 22

        outlineView.intercellSpacing = NSSize(
            width: 0,
            height: 0
        )

        scrollView.documentView = outlineView

        view.addSubview(modeSeparator)

        view.addSubview(scrollView)

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

    // MARK: - Search

    @objc private func searchFieldChanged(
        _ sender: NSSearchField
    ) {

        filterFinancialItems(
            searchText:
                sender.stringValue
        )
    }

    private func filterFinancialItems(
        searchText: String
    ) {

        let trimmedText = searchText
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        // -------------------------------------------------
        // KALEM MODU
        // -------------------------------------------------

        if modeToggle.selectedSegment == 0 {

            if trimmedText.isEmpty {

                rebuildNodes(
                    from:
                        allFinancialItems
                )

            } else {

                let filteredItems =
                    filteredItems(
                        matching:
                            trimmedText
                    )

                rebuildNodes(
                    from:
                        filteredItems
                )
            }

            return
        }

        // -------------------------------------------------
        // GRUP MODU
        // -------------------------------------------------

        rebuildGroupNodes(
            searchText:
                trimmedText
        )
    }

    private func filteredItems(
        matching searchText: String
    ) -> [FinancialStatementItem] {

        allFinancialItems.filter {

            let title = $0.titleTR.isEmpty
                ? $0.itemCode
                : $0.titleTR

            let titleMatches =
                title.range(
                    of:
                        searchText,
                    options: [
                        .caseInsensitive,
                        .diacriticInsensitive
                    ],
                    locale:
                        Locale(identifier: "tr_TR")
                ) != nil

            let codeMatches =
                $0.itemCode.range(
                    of:
                        searchText,
                    options: [
                        .caseInsensitive,
                        .diacriticInsensitive
                    ],
                    locale:
                        Locale(identifier: "tr_TR")
                ) != nil

            return titleMatches || codeMatches
        }
    }

    // MARK: - Item Nodes

    private func rebuildNodes(
        from items:
            [FinancialStatementItem]
    ) {

        nodes.removeAll(
            keepingCapacity:
                true
        )

        let sortedItems = items.sorted {

            $0.itemCode.localizedStandardCompare(
                $1.itemCode
            ) == .orderedAscending
        }

        for item in sortedItems {

            let title = item.titleTR.isEmpty
                ? item.itemCode
                : item.titleTR

            let node = FundamentalSidebarNode(

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

            nodes.append(node)
        }

        outlineView.reloadData()

        restoreLastItemSelection()
    }

    // MARK: - Group Nodes

    private func rebuildGroupNodes(
        searchText:
            String
    ) {

        nodes.removeAll(
            keepingCapacity:
                true
        )

        groupsToExpandAfterReload.removeAll()

        let trimmedText =
            searchText.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        for group in FundamentalGroup.all {

            // Grubun API'den gerçekten gelen kalemleri.
            let groupItems =
                group.itemCodes.compactMap {
                    code in

                    allFinancialItems.first {
                        $0.itemCode == code
                    }
                }

            guard !groupItems.isEmpty else {
                continue
            }

            // -------------------------------------------------
            // Arama yok
            // -------------------------------------------------

            if trimmedText.isEmpty {

                let groupNode =
                    makeGroupNode(
                        group:
                            group,
                        items:
                            groupItems
                    )

                nodes.append(
                    groupNode
                )

                continue
            }

            // -------------------------------------------------
            // Arama var
            // -------------------------------------------------

            let groupMatches =
                matches(
                    text:
                        group.title,
                    searchText:
                        trimmedText
                )

            let matchingItems =
                groupItems.filter {

                    let title =
                        $0.titleTR.isEmpty
                        ? $0.itemCode
                        : $0.titleTR

                    return matches(
                        text:
                            title,
                        searchText:
                            trimmedText
                    )
                    ||
                    matches(
                        text:
                            $0.itemCode,
                        searchText:
                            trimmedText
                    )
                }

            // Grup adı eşleşirse grubun tamamını göster.
            if groupMatches {

                let groupNode =
                    makeGroupNode(
                        group:
                            group,
                        items:
                            groupItems
                    )

                nodes.append(
                    groupNode
                )

                groupsToExpandAfterReload.insert(
                    group.id
                )

                continue
            }

            // Kalem adı eşleşirse sadece eşleşen
            // çocukları göster.
            if !matchingItems.isEmpty {

                let groupNode =
                    makeGroupNode(
                        group:
                            group,
                        items:
                            matchingItems
                    )

                nodes.append(
                    groupNode
                )

                groupsToExpandAfterReload.insert(
                    group.id
                )
            }
        }

        outlineView.reloadData()

        expandGroupsAfterReload()
    }

    private func makeGroupNode(
        group: FundamentalGroup,
        items: [FinancialStatementItem]
    ) -> FundamentalSidebarNode {

        var children: [FundamentalSidebarNode] = []

        for itemCode in group.itemCodes {

            guard let item = items.first(
                where: {
                    $0.itemCode == itemCode
                }
            ) else {
                continue
            }

            let title =
                item.titleTR.isEmpty
                ? item.itemCode
                : item.titleTR

            let child =
                FundamentalSidebarNode(
                    title: title,
                    selection: .single(
                        itemCode: item.itemCode
                    ),
                    children: [],
                    isGroup: false
                )

            children.append(child)
        }

        return FundamentalSidebarNode(
            title: group.title,
            selection: .group(
                itemCodes: group.itemCodes
            ),
            children: children,
            isGroup: true
        )
    }

    private func matches(
        text:
            String,
        searchText:
            String
    ) -> Bool {

        text.range(
            of:
                searchText,
            options: [
                .caseInsensitive,
                .diacriticInsensitive
            ],
            locale:
                Locale(identifier: "tr_TR")
        ) != nil
    }

    // MARK: - Group Expansion

    private func expandGroupsAfterReload() {

        guard !groupsToExpandAfterReload.isEmpty else {
            return
        }

        // Reload sonrasında outline'ın item'ları
        // oluşturması için bir sonraki run loop'u bekliyoruz.
        DispatchQueue.main.async { [weak self] in

            guard let self = self else {
                return
            }

            for row in 0..<self.outlineView.numberOfRows {

                guard
                    let node =
                        self.outlineView.item(
                            atRow:
                                row
                        ) as? FundamentalSidebarNode
                else {
                    continue
                }

                guard
                    node.isGroup,
                    let group =
                        FundamentalGroup.all.first(
                            where:
                                {
                                    $0.title == node.title
                                }
                        )
                else {
                    continue
                }

                if self.groupsToExpandAfterReload
                    .contains(group.id) {

                    self.outlineView.expandItem(
                        node
                    )
                }
            }

            self.groupsToExpandAfterReload.removeAll()
        }
    }

    // MARK: - Mode

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

    private func switchToItemMode() {

        print(
            "TEMEL SIDEBAR MODU: KALEM"
        )

        let searchText =
            searchField.stringValue

        filterFinancialItems(
            searchText:
                searchText
        )

        // Son seçili kalem varsa grafik tarafında
        // aynı kalemi koru.
        if let itemCode =
            lastSelectedItemCode {

            delegate?.fundamentalSidebar(
                self,
                didSelect:
                    .single(
                        itemCode:
                            itemCode
                    )
            )
        }
    }

    private func switchToGroupMode() {

        print(
            "TEMEL SIDEBAR MODU: GRUP"
        )

        // Artık önce bir kalem seçilmiş olması
        // gerekmiyor.
        //
        // Doğrudan grup ağacını oluşturuyoruz.
        let searchText =
            searchField.stringValue

        rebuildGroupNodes(
            searchText:
                searchText
        )
    }

    // MARK: - Selection Restoration

    private func restoreLastItemSelection() {

        guard
            let itemCode =
                lastSelectedItemCode
        else {
            return
        }

        DispatchQueue.main.async { [weak self] in

            guard let self = self else {
                return
            }

            for row in 0..<self.outlineView.numberOfRows {

                guard
                    let node =
                        self.outlineView.item(
                            atRow:
                                row
                        ) as? FundamentalSidebarNode
                else {
                    continue
                }

                if case .single(
                    let code
                ) = node.selection,
                   code == itemCode {

                    self.outlineView.selectRowIndexes(
                        IndexSet(
                            integer:
                                row
                        ),
                        byExtendingSelection:
                            false
                    )

                    break
                }
            }
        }
    }

    // MARK: - Public Data

    func updateFinancialItems(
        items:
            [FinancialStatementItem]
    ) {

        allFinancialItems =
            items

        let searchText =
            searchField.stringValue

        if modeToggle.selectedSegment == 0 {

            if searchText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty {

                rebuildNodes(
                    from:
                        items
                )

            } else {

                filterFinancialItems(
                    searchText:
                        searchText
                )
            }

        } else {

            rebuildGroupNodes(
                searchText:
                    searchText
            )
        }

        print(
            "Fundamental sidebar güncellendi. Kalem sayısı: \(items.count)"
        )
    }

    func clearFinancialItems() {

        nodes.removeAll()

        allFinancialItems.removeAll()

        lastSelectedItemCode = nil

        groupsToExpandAfterReload.removeAll()

        searchField.stringValue = ""

        outlineView.deselectAll(nil)

        outlineView.reloadData()
    }

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

// MARK: - NSOutlineViewDataSource

extension FundamentalSidebarViewController:
    NSOutlineViewDataSource {

    func outlineView(
        _ outlineView:
            NSOutlineView,
        numberOfChildrenOfItem item:
            Any?
    ) -> Int {

        if let node =
            item as? FundamentalSidebarNode {

            return node.children.count
        }

        return nodes.count
    }

    func outlineView(
        _ outlineView:
            NSOutlineView,
        isItemExpandable item:
            Any
    ) -> Bool {

        guard
            let node =
                item as? FundamentalSidebarNode
        else {
            return false
        }

        return !node.children.isEmpty
    }

    func outlineView(
        _ outlineView:
            NSOutlineView,
        child index:
            Int,
        ofItem item:
            Any?
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
        _ outlineView:
            NSOutlineView,
        viewFor tableColumn:
            NSTableColumn?,
        item:
            Any
    ) -> NSView? {

        guard
            let node =
                item as? FundamentalSidebarNode
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
            ) as? NSTableCellView
            ?? NSTableCellView()

        cell.identifier =
            identifier

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
                ) as? FundamentalSidebarNode
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

        // -------------------------------------------------
        // TEK FİNANSAL KALEM
        // -------------------------------------------------

        case .single(
            let itemCode
        ):

            lastSelectedItemCode =
                itemCode

            print(
                "SON SEÇİLEN FİNANSAL KALEM: \(itemCode)"
            )

            // ÖNEMLİ:
            //
            // Grup modunda bile çocuk kalem
            // seçildiğinde sadece o kalem açılır.
            delegate?.fundamentalSidebar(
                self,
                didSelect:
                    .single(
                        itemCode:
                            itemCode
                    )
            )

        // -------------------------------------------------
        // GRUP
        // -------------------------------------------------

        case .group(
            let itemCodes
        ):

            print(
                "SEÇİLEN FİNANSAL GRUP"
            )

            print(
                "Grup kalemleri: \(itemCodes)"
            )

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
