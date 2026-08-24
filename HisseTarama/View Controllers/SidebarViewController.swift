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

    // MARK: - Global Controls

    private let currencyControl: NSSegmentedControl = {
        let control = NSSegmentedControl(
            labels: ["TRY", "USD"],
            trackingMode: .selectOne,
            target: nil,
            action: nil
        )

        control.selectedSegment = 0
        control.segmentStyle = .rounded

        // Daha büyük yazı
        control.font = NSFont.systemFont(
            ofSize: 16,
            weight: .semibold
        )

        return control
    }()

    private let symbolTextField: NSTextField = {
        let textField = NSTextField()

        textField.placeholderString = "Hisse"
        textField.font = NSFont.systemFont(ofSize: 13)

        return textField
    }()

    private let fetchButton: NSButton = {
        let button = NSButton()

        button.bezelStyle = .texturedRounded
        button.isBordered = true
        button.imagePosition = .imageOnly
        button.toolTip = "Hisse verilerini getir / güncelle"

        if #available(macOS 11.0, *) {
            button.image = NSImage(
                systemSymbolName: "arrow.clockwise",
                accessibilityDescription: "Güncelle"
            )
        } else {
            button.title = "↻"
        }

        return button
    }()

    private let globalControlsStack: NSStackView = {

        let stack = NSStackView()

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 8

        return stack
    }()

    private let symbolRowStack: NSStackView = {
        let stack = NSStackView()

        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.distribution = .fill
        stack.spacing = 6

        return stack
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureGlobalControls()
        configureOutlineView()
        rebuildItems()
        updateControlsFromGlobalState()

        setupGlobalSelectionObservers()
    }
    
    
   

    // MARK: - Global Selection

    @objc private func currencyChanged(
        _ sender: NSSegmentedControl
    ) {

        switch sender.selectedSegment {

        case 0:
            AppSelectionState.shared.setCurrency(
                .tryCurrency
            )

        case 1:
            AppSelectionState.shared.setCurrency(
                .usd
            )

        default:
            break
        }
    }

    @objc private func fetchButtonClicked() {

        let symbol =
            symbolTextField.stringValue
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        guard !symbol.isEmpty else {
            return
        }

        symbolTextField.stringValue = symbol

        AppSelectionState.shared.setSymbol(
            symbol
        )
    }
    
    private func updateControlsFromGlobalState() {

        symbolTextField.stringValue =
            AppSelectionState.shared.selectedSymbol

        switch AppSelectionState.shared.selectedCurrency {

        case .tryCurrency:
            currencyControl.selectedSegment = 0

        case .usd:
            currencyControl.selectedSegment = 1
        }
    }
    
    private func setupGlobalSelectionObservers() {

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(globalSymbolChanged(_:)),
            name: AppSelectionState.symbolDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(globalCurrencyChanged(_:)),
            name: AppSelectionState.currencyDidChange,
            object: nil
        )
    }
    
    @objc private func globalSymbolChanged(
        _ notification: Notification
    ) {
        symbolTextField.stringValue =
            AppSelectionState.shared.selectedSymbol
    }
    
    @objc private func globalCurrencyChanged(
        _ notification: Notification
    ) {
        switch AppSelectionState.shared.selectedCurrency {

        case .tryCurrency:
            currencyControl.selectedSegment = 0

        case .usd:
            currencyControl.selectedSegment = 1
        }
    }
    
    // MARK: - Global Controls

    private func configureGlobalControls() {

        globalControlsStack.translatesAutoresizingMaskIntoConstraints = false
        symbolRowStack.translatesAutoresizingMaskIntoConstraints = false
        currencyControl.translatesAutoresizingMaskIntoConstraints = false
        symbolTextField.translatesAutoresizingMaskIntoConstraints = false
        fetchButton.translatesAutoresizingMaskIntoConstraints = false

        // -------------------------------------------------
        // Hisse satırı
        // -------------------------------------------------

        symbolRowStack.addArrangedSubview(symbolTextField)
        symbolRowStack.addArrangedSubview(fetchButton)

        // -------------------------------------------------
        // Ana kontrol alanı
        // -------------------------------------------------

        globalControlsStack.addArrangedSubview(currencyControl)
        globalControlsStack.addArrangedSubview(symbolRowStack)

        view.addSubview(globalControlsStack)

        // -------------------------------------------------
        // Kontrol alanı
        // -------------------------------------------------

        NSLayoutConstraint.activate([

            globalControlsStack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 10
            ),

            globalControlsStack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -10
            ),

            globalControlsStack.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 50
            ),

            currencyControl.widthAnchor.constraint(
                equalTo: globalControlsStack.widthAnchor
            ),

            currencyControl.heightAnchor.constraint(
                equalToConstant: 44
            ),

            symbolRowStack.leadingAnchor.constraint(
                equalTo: globalControlsStack.leadingAnchor
            ),

            symbolRowStack.trailingAnchor.constraint(
                equalTo: globalControlsStack.trailingAnchor
            ),

            symbolTextField.heightAnchor.constraint(
                equalToConstant: 26
            ),

            fetchButton.widthAnchor.constraint(
                equalToConstant: 30
            ),

            fetchButton.heightAnchor.constraint(
                equalToConstant: 26
            )
        ])

        // -------------------------------------------------
        // OutlineView'ın içinde bulunduğu ScrollView
        // -------------------------------------------------

        guard let scrollView = outlineView.enclosingScrollView else {
            return
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Storyboard'dan gelen mevcut konum constraint'lerini
        // kaldırıyoruz.
        removeConstraintsForScrollView(scrollView)

        NSLayoutConstraint.activate([

            scrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),

            scrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),

            scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),

            scrollView.topAnchor.constraint(
                equalTo: globalControlsStack.bottomAnchor,
                constant: 12
            )
        ])

        // -------------------------------------------------
        // Actions
        // -------------------------------------------------

        currencyControl.target = self
        currencyControl.action = #selector(currencyChanged)

        fetchButton.target = self
        fetchButton.action = #selector(fetchButtonClicked)

        // Hisse kutusundayken Enter → veri getir
        symbolTextField.target = self
        symbolTextField.action = #selector(fetchButtonClicked)

        // Kontroller scroll view'ın üzerinde görünsün.
        view.addSubview(
            globalControlsStack,
            positioned: .above,
            relativeTo: scrollView
        )
    }

    // MARK: - Scroll View Constraints

    private func removeConstraintsForScrollView(
        _ scrollView: NSScrollView
    ) {

        let constraints = view.constraints.filter { constraint in

            guard
                let firstView = constraint.firstItem as? NSView
            else {
                return false
            }

            let secondView =
                constraint.secondItem as? NSView

            return firstView === scrollView ||
                   secondView === scrollView
        }

        view.removeConstraints(constraints)
    }

    // MARK: - Outline View

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

// MARK: - NSOutlineViewDataSource

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

// MARK: - NSOutlineViewDelegate

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
