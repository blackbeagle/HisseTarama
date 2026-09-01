import Cocoa

final class FundamentalsViewController: NSViewController {

    // MARK: - Child View Controllers

    private let sidebarViewController =
        FundamentalSidebarViewController()

    private let chartViewController =
        FundamentalChartViewController()

    // MARK: - Data

    private var financialItems:
        [FinancialStatementItem] = []

    private var financialPeriods:
        [FinancialPeriod] = []

    private var currentStockSymbol:
        String?

    // -------------------------------------------------
    // Veri çekme durumu
    // -------------------------------------------------

    private var currentFetchID = UUID()

    // MARK: - Loading Overlay

    private var loadingOverlay: NSView?

    private var loadingIndicator:
        NSProgressIndicator?

    private var loadingLabel:
        NSTextField?

    // MARK: - UI

    private let separatorView: NSBox = {
        let box = NSBox()
        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints =
            false
        return box
    }()

    // MARK: - Data Fetch Result

    var onDataFetchCompleted:
        ((String, Bool) -> Void)?

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setupView()
        setupSidebar()
        setupChart()
        setupGlobalSelectionObservers()

        // Uygulama açılırken global state'te
        // bir hisse varsa yükle.

        let symbol =
            AppSelectionState.shared.selectedSymbol

        if !symbol.isEmpty {
            selectStock(
                symbol: symbol
            )
        }
    }

    // MARK: - Global Selection

    private func setupGlobalSelectionObservers() {

        NotificationCenter.default.addObserver(
            self,
            selector:
                #selector(globalSymbolChanged(_:)),
            name:
                AppSelectionState.symbolDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector:
                #selector(globalCurrencyChanged(_:)),
            name:
                AppSelectionState.currencyDidChange,
            object: nil
        )
    }

    @objc private func globalSymbolChanged(
        _ notification: Notification
    ) {

        let symbol =
            AppSelectionState.shared.selectedSymbol

        guard !symbol.isEmpty else {
            return
        }

        selectStock(
            symbol: symbol
        )
    }

    @objc private func globalCurrencyChanged(
        _ notification: Notification
    ) {

        print(
            "TEMEL GLOBAL PARA BİRİMİ:",
            AppSelectionState.shared
                .selectedCurrency
                .stockCurrency
                .apiValue
        )

        guard
            let symbol = currentStockSymbol,
            !symbol.isEmpty
        else {
            return
        }

        // -------------------------------------------------
        // Para birimi değiştiğinde eski finansal verileri
        // temizliyoruz.
        // -------------------------------------------------

        // financialItems.removeAll()
        // financialPeriods.removeAll()
        // chartViewController.clearChart()

        // -------------------------------------------------
        // Yeni para birimiyle tekrar veri çek.
        // -------------------------------------------------

        fetchFinancialData(
            for: symbol
        )
    }

    deinit {

        NotificationCenter.default.removeObserver(
            self
        )
    }

    // MARK: - Setup

    private func setupView() {

        view.wantsLayer = true
    }

    private func setupSidebar() {

        addChild(
            sidebarViewController
        )

        sidebarViewController.delegate = self

        let sidebarView =
            sidebarViewController.view

        sidebarView.translatesAutoresizingMaskIntoConstraints =
            false

        view.addSubview(
            sidebarView
        )

        view.addSubview(
            separatorView
        )

        NSLayoutConstraint.activate([

            sidebarView.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor
            ),

            sidebarView.topAnchor.constraint(
                equalTo:
                    view.topAnchor
            ),

            sidebarView.bottomAnchor.constraint(
                equalTo:
                    view.bottomAnchor
            ),

            sidebarView.widthAnchor.constraint(
                equalToConstant:
                    250
            ),

            separatorView.leadingAnchor.constraint(
                equalTo:
                    sidebarView.trailingAnchor
            ),

            separatorView.topAnchor.constraint(
                equalTo:
                    view.topAnchor
            ),

            separatorView.bottomAnchor.constraint(
                equalTo:
                    view.bottomAnchor
            ),

            separatorView.widthAnchor.constraint(
                equalToConstant:
                    1
            )
        ])
    }

    private func setupChart() {

        addChild(
            chartViewController
        )

        let chartView =
            chartViewController.view

        chartView.translatesAutoresizingMaskIntoConstraints =
            false

        view.addSubview(
            chartView
        )

        NSLayoutConstraint.activate([

            chartView.leadingAnchor.constraint(
                equalTo:
                    separatorView.trailingAnchor
            ),

            chartView.trailingAnchor.constraint(
                equalTo:
                    view.trailingAnchor
            ),

            chartView.topAnchor.constraint(
                equalTo:
                    view.topAnchor
            ),

            chartView.bottomAnchor.constraint(
                equalTo:
                    view.bottomAnchor
            )
        ])
    }

    // MARK: - Loading Overlay

    private func showLoadingOverlay(
        for symbol: String
    ) {

        hideLoadingOverlay()

        let overlay = NSView()

        overlay.translatesAutoresizingMaskIntoConstraints =
            false

        overlay.wantsLayer = true

        overlay.layer?.backgroundColor =
            NSColor.windowBackgroundColor
                .withAlphaComponent(0.78)
                .cgColor

        // -------------------------------------------------
        // Loading sadece temel grafik alanını kaplar.
        //
        // Sidebar çalışmaya devam eder.
        // Eski grafik ise overlay'in altında korunur.
        // -------------------------------------------------

        let targetView =
            chartViewController.view

        targetView.addSubview(
            overlay
        )

        NSLayoutConstraint.activate([

            overlay.leadingAnchor.constraint(
                equalTo:
                    targetView.leadingAnchor
            ),

            overlay.trailingAnchor.constraint(
                equalTo:
                    targetView.trailingAnchor
            ),

            overlay.topAnchor.constraint(
                equalTo:
                    targetView.topAnchor
            ),

            overlay.bottomAnchor.constraint(
                equalTo:
                    targetView.bottomAnchor
            )
        ])

        // -------------------------------------------------
        // Indicator
        // -------------------------------------------------

        let indicator =
            NSProgressIndicator()

        indicator.style = .spinning
        indicator.controlSize = .regular
        indicator.isIndeterminate = true

        indicator.translatesAutoresizingMaskIntoConstraints =
            false

        indicator.startAnimation(nil)

        overlay.addSubview(
            indicator
        )

        // -------------------------------------------------
        // Label
        // -------------------------------------------------

        let label =
            NSTextField(
                labelWithString:
                    "\(symbol) temel verileri getiriliyor..."
            )

        label.font =
            NSFont.systemFont(
                ofSize: 14,
                weight: .medium
            )

        label.textColor =
            NSColor.labelColor

        label.alignment = .center

        label.translatesAutoresizingMaskIntoConstraints =
            false

        overlay.addSubview(
            label
        )

        NSLayoutConstraint.activate([

            indicator.centerXAnchor.constraint(
                equalTo:
                    overlay.centerXAnchor
            ),

            indicator.centerYAnchor.constraint(
                equalTo:
                    overlay.centerYAnchor,
                constant:
                    -12
            ),

            label.centerXAnchor.constraint(
                equalTo:
                    overlay.centerXAnchor
            ),

            label.topAnchor.constraint(
                equalTo:
                    indicator.bottomAnchor,
                constant:
                    12
            )
        ])

        loadingOverlay = overlay
        loadingIndicator = indicator
        loadingLabel = label
    }

    private func hideLoadingOverlay() {

        loadingIndicator?.stopAnimation(nil)

        loadingOverlay?.removeFromSuperview()

        loadingOverlay = nil
        loadingIndicator = nil
        loadingLabel = nil
    }

    // MARK: - Stock Selection

    func selectStock(
        symbol: String
    ) {

        let normalizedSymbol =
            symbol
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        guard !normalizedSymbol.isEmpty else {
            return
        }

        currentStockSymbol =
            normalizedSymbol

        print(
            "Temel sekmesi hisse güncellendi: \(normalizedSymbol)"
        )

        // -------------------------------------------------
        // Önce eski finansal verileri temizle.
        // -------------------------------------------------

        // financialItems.removeAll()
        // financialPeriods.removeAll()

        // -------------------------------------------------
        // Eski grafiği temizle.
        // -------------------------------------------------

        // chartViewController.clearChart()

        // -------------------------------------------------
        // Sidebar'daki hisseyi güncelle.
        // -------------------------------------------------

        sidebarViewController.updateStock(
            symbol:
                normalizedSymbol
        )

        // -------------------------------------------------
        // Yeni veri çek.
        // -------------------------------------------------

        fetchFinancialData(
            for:
                normalizedSymbol
        )
    }

    // MARK: - Financial Data

    private func fetchFinancialData(
        for symbol: String
    ) {

        print("================================")

        print(
            "TEMEL VERİ ÇEKİMİ BAŞLADI"
        )

        print(
            "Hisse: \(symbol)"
        )

        print("================================")

        let currency =
            AppSelectionState.shared
                .selectedCurrency
                .stockCurrency

        print(
            "TEMEL SORGU PARA BİRİMİ:",
            currency.apiValue
        )

        // -------------------------------------------------
        // Yeni istek kimliği
        //
        // Teknik sekmedeki mantığın aynısı:
        //
        // Örneğin:
        //
        // SISE temel verisi beklenirken
        // THYAO seçilirse ve SISE cevabı
        // daha sonra gelirse SISE sonucu
        // kabul edilmeyecek.
        // -------------------------------------------------

        let fetchID = UUID()

        currentFetchID = fetchID

        // -------------------------------------------------
        // Loading göster.
        //
        // Eski grafik temizlenmedi.
        // Overlay grafiğin üzerinde gösterilecek.
        // -------------------------------------------------

        showLoadingOverlay(
            for:
                symbol
        )

        let query =
            StockDataQuery(
                lastFinancialPeriod:
                    nil,
                financialQuarterCount:
                    10,
                currency:
                    currency
            )

        FinancialDataService.shared
            .fetchFinancialStatements(
                companyCode:
                    symbol,
                query:
                    query
            ) { [weak self] result in

                DispatchQueue.main.async {

                    guard let self = self else {
                        return
                    }

                    // -------------------------------------------------
                    // Bu cevap artık güncel değil.
                    // -------------------------------------------------

                    guard
                        self.currentFetchID == fetchID
                    else {
                        return
                    }

                    switch result {

                    case .success(let statements):

                        // -------------------------------------------------
                        // Loading kapat
                        // -------------------------------------------------

                        self.hideLoadingOverlay()

                        self.onDataFetchCompleted?(
                            symbol,
                            true
                        )

                        print("================================")
                        print("TEMEL VERİ ALINDI")
                        print("================================")

                        print(
                            "Dönem sayısı: \(statements.periods.count)"
                        )

                        print(
                            "Finansal kalem sayısı: \(statements.items.count)"
                        )

                        self.updateFinancialData(
                            items:
                                statements.allItems,
                            periods:
                                statements.periods
                        )

                    case .failure(let error):

                        // -------------------------------------------------
                        // Loading kapat
                        // -------------------------------------------------

                        self.hideLoadingOverlay()

                        print(
                            "TEMEL CALLBACK ÇAĞRILIYOR: \(symbol) - false"
                        )

                        self.onDataFetchCompleted?(
                            symbol,
                            false
                        )

                        print("================================")
                        print("TEMEL VERİ HATASI")
                        print("================================")

                        print(
                            "Hata: \(error.localizedDescription)"
                        )
                    }
                }
            }
    }

    // MARK: - Financial Data Update

    func updateFinancialData(
        items:
            [FinancialStatementItem],
        periods:
            [FinancialPeriod]
    ) {

        print(
            ">>> updateFinancialData ÇAĞRILDI <<<"
        )

        // ---------------------------------------------------------
        // Finansal verileri controller içinde sakla
        // ---------------------------------------------------------

        financialItems =
            items

        financialPeriods =
            periods

        print(
            "Gelen finansal kalem sayısı: \(items.count)"
        )

        print(
            "Gelen finansal dönem sayısı: \(periods.count)"
        )

        print(
            "financialItems artık: \(financialItems.count)"
        )

        print(
            "financialPeriods artık: \(financialPeriods.count)"
        )

        // ---------------------------------------------------------
        // Finansal kalemleri sol sidebar'a gönder
        // ---------------------------------------------------------

        sidebarViewController.updateFinancialItems(
            items:
                financialItems
        )

        print(
            ">>> Fundamental sidebar finansal verilerle güncellendi <<<"
        )

        // ---------------------------------------------------------
        // Grafik para birimini güncelle
        //
        // USD modunda sütun değerlerinin sonunda "$"
        // gösterilecek.
        // ---------------------------------------------------------

        let isUSD =
            AppSelectionState.shared
                .selectedCurrency
                .stockCurrency
                .apiValue
                .uppercased() == "USD"

        chartViewController.setCurrency(
            isUSD:
                isUSD
        )

        // ---------------------------------------------------------
        // Mevcut grafiği temizle
        // ---------------------------------------------------------

        chartViewController.clearChart()

        // ---------------------------------------------------------
        // Test amacıyla ilk finansal kalemi grafiğe gönder
        // ---------------------------------------------------------

        if
            !financialItems.isEmpty &&
            !financialPeriods.isEmpty
        {

            let firstItem =
                financialItems[0]

            print(
                "Test grafik kalemi: \(firstItem.itemCode) - \(firstItem.titleTR)"
            )

            chartViewController.show(
                items:
                    [firstItem],
                periods:
                    financialPeriods
            )

            print(
                ">>> chartViewController.show() ÇAĞRILDI <<<"
            )
        }

        print(
            "Temel grafik verisi güncellendi."
        )
    }

    // MARK: - Selection

    private func showSelection(
        _ selection:
            FundamentalSelection
    ) {

        guard
            !financialItems.isEmpty,
            !financialPeriods.isEmpty
        else {

            print(
                "Temel grafik: Henüz finansal veri yok."
            )

            return
        }

        let selectedItems:
            [FinancialStatementItem]

        switch selection {

        case .single(
            let itemCode
        ):

            selectedItems =
                financialItems.filter {
                    $0.itemCode ==
                        itemCode
                }

        case .group(
            let itemCodes
        ):

            selectedItems =
                itemCodes.compactMap {
                    code in

                    financialItems.first {
                        $0.itemCode ==
                            code
                    }
                }
        }

        guard !selectedItems.isEmpty else {

            print(
                "Temel grafik: Seçilen kalem bulunamadı."
            )

            return
        }

        print(
            "Temel grafik seçimi:"
        )

        for item in selectedItems {

            print(
                "\(item.itemCode) - \(item.name)"
            )
        }

        chartViewController.show(
            items:
                selectedItems,
            periods:
                financialPeriods
        )
    }

    // MARK: - Alert

    private func showAlert(
        message: String
    ) {

        let alert =
            NSAlert()

        alert.messageText =
            "Temel Veri Alınamadı"

        alert.informativeText =
            message

        alert.alertStyle =
            .warning

        alert.addButton(
            withTitle:
                "Tamam"
        )

        alert.runModal()
    }
}

// MARK: - FundamentalSidebarDelegate

extension FundamentalsViewController:
    FundamentalSidebarDelegate {

    func fundamentalSidebar(
        _ sidebar:
            FundamentalSidebarViewController,
        didSelect selection:
            FundamentalSelection
    ) {

        showSelection(
            selection
        )
    }
}


