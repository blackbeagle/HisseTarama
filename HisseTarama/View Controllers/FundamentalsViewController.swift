
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

    // MARK: - Selection

    private var currentSelection:
        FundamentalSelection?

    // MARK: - Request Control

    private var currentFetchID =
        UUID()

    // MARK: - Loading Overlay

    private var loadingOverlay:
        NSView?

    private var loadingIndicator:
        NSProgressIndicator?

    private var loadingLabel:
        NSTextField?

    // MARK: - UI

    private let separatorView: NSBox = {

        let box =
            NSBox()

        box.boxType =
            .separator

        box.translatesAutoresizingMaskIntoConstraints =
            false

        return box
    }()

    // MARK: - Data Fetch Result

    var onDataFetchCompleted:
        ((String, Bool) -> Void)?

    // MARK: - Lifecycle

    override func loadView() {

        view =
            NSView()
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
                symbol:
                    symbol
            )
        }
    }

    deinit {

        NotificationCenter.default.removeObserver(
            self
        )
    }

    // MARK: - Setup

    private func setupView() {

        view.wantsLayer =
            true
    }

    private func setupSidebar() {

        addChild(
            sidebarViewController
        )

        sidebarViewController.delegate =
            self

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

    // MARK: - Global Selection

    private func setupGlobalSelectionObservers() {

        NotificationCenter.default.addObserver(
            self,
            selector:
                #selector(
                    globalSymbolChanged(_:)
                ),
            name:
                AppSelectionState.symbolDidChange,
            object:
                nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector:
                #selector(
                    globalCurrencyChanged(_:)
                ),
            name:
                AppSelectionState.currencyDidChange,
            object:
                nil
        )
    }

    @objc
    private func globalSymbolChanged(
        _ notification:
            Notification
    ) {

        let symbol =
            AppSelectionState.shared.selectedSymbol

        guard
            !symbol.isEmpty
        else {
            return
        }

        selectStock(
            symbol:
                symbol
        )
    }

    @objc
    private func globalCurrencyChanged(
        _ notification:
            Notification
    ) {

        print(
            "TEMEL GLOBAL PARA BİRİMİ:",
            AppSelectionState.shared
                .selectedCurrency
                .stockCurrency
                .apiValue
        )

        guard
            let symbol =
                currentStockSymbol,
            !symbol.isEmpty
        else {
            return
        }

        // Para birimi değiştiğinde aynı finansal
        // kalem / grup seçimi korunur.
        //
        // Sadece veriler yeni para birimiyle
        // tekrar alınır.

        fetchFinancialData(
            for:
                symbol
        )
    }

    // MARK: - Loading Overlay

    private func showLoadingOverlay(
        for symbol:
            String
    ) {

        hideLoadingOverlay()

        let overlay =
            NSView()

        overlay.translatesAutoresizingMaskIntoConstraints =
            false

        overlay.wantsLayer =
            true

        overlay.layer?.backgroundColor =
            NSColor.windowBackgroundColor
                .withAlphaComponent(
                    0.78
                )
                .cgColor

        // Loading sadece temel grafik alanını
        // kaplar. Sidebar çalışmaya devam eder.

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

        // MARK: Indicator

        let indicator =
            NSProgressIndicator()

        indicator.style =
            .spinning

        indicator.controlSize =
            .regular

        indicator.isIndeterminate =
            true

        indicator.translatesAutoresizingMaskIntoConstraints =
            false

        indicator.startAnimation(
            nil
        )

        overlay.addSubview(
            indicator
        )

        // MARK: Label

        let label =
            NSTextField(
                labelWithString:
                    "\(symbol) temel verileri getiriliyor..."
            )

        label.font =
            NSFont.systemFont(
                ofSize:
                    14,
                weight:
                    .medium
            )

        label.textColor =
            NSColor.labelColor

        label.alignment =
            .center

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

        loadingOverlay =
            overlay

        loadingIndicator =
            indicator

        loadingLabel =
            label
    }

    private func hideLoadingOverlay() {

        loadingIndicator?.stopAnimation(
            nil
        )

        loadingOverlay?.removeFromSuperview()

        loadingOverlay =
            nil

        loadingIndicator =
            nil

        loadingLabel =
            nil
    }

    // MARK: - Stock Selection

    func selectStock(
        symbol:
            String
    ) {

        let normalizedSymbol =
            symbol
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .uppercased()

        guard
            !normalizedSymbol.isEmpty
        else {
            return
        }

        currentStockSymbol =
            normalizedSymbol

        print(
            "Temel sekmesi hisse güncellendi: \(normalizedSymbol)"
        )

        sidebarViewController.updateStock(
            symbol:
                normalizedSymbol
        )

        fetchFinancialData(
            for:
                normalizedSymbol
        )
    }

    // MARK: - Financial Data

    private func fetchFinancialData(
        for symbol:
            String
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

        // MARK: Request ID

        let fetchID =
            UUID()

        currentFetchID =
            fetchID

        // MARK: Loading

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
            ) {
                [weak self] result in

                DispatchQueue.main.async {

                    guard
                        let self =
                            self
                    else {
                        return
                    }

                    // Eski istek artık geçersiz.

                    guard
                        self.currentFetchID ==
                            fetchID
                    else {
                        return
                    }

                    switch result {

                    case .success(
                        let statements
                    ):

                        self.hideLoadingOverlay()

                        self.onDataFetchCompleted?(
                            symbol,
                            true
                        )

                        print(
                            "================================"
                        )

                        print(
                            "TEMEL VERİ ALINDI"
                        )

                        print(
                            "================================"
                        )

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

                    case .failure(
                        let error
                    ):

                        self.hideLoadingOverlay()

                        print(
                            "TEMEL CALLBACK ÇAĞRILIYOR: \(symbol) - false"
                        )

                        self.onDataFetchCompleted?(
                            symbol,
                            false
                        )

                        print(
                            "================================"
                        )

                        print(
                            "TEMEL VERİ HATASI"
                        )

                        print(
                            "================================"
                        )

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

        // -------------------------------------------------
        // Eski sidebar kalem kodlarını sakla.
        // -------------------------------------------------

        let previousItemCodes =
            Set(
                financialItems.map {
                    $0.itemCode
                }
            )

        let newItemCodes =
            Set(
                items.map {
                    $0.itemCode
                }
            )

        let sidebarNeedsUpdate =
            previousItemCodes !=
                newItemCodes

        // -------------------------------------------------
        // Finansal verileri controller içinde sakla.
        // -------------------------------------------------

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

        // -------------------------------------------------
        // Sidebar
        // -------------------------------------------------

        if sidebarNeedsUpdate {

            sidebarViewController.updateFinancialItems(
                items:
                    financialItems
            )

            print(
                ">>> Fundamental sidebar yeniden oluşturuldu <<<"
            )

        } else {

            print(
                ">>> Fundamental sidebar yeniden yüklenmedi <<<"
            )
        }

        // -------------------------------------------------
        // Grafik para birimini güncelle.
        // -------------------------------------------------

        let isUSD =
            AppSelectionState.shared
                .selectedCurrency
                .stockCurrency
                .apiValue
                .uppercased() ==
                "USD"

        chartViewController.setCurrency(
            isUSD:
                isUSD
        )

        // -------------------------------------------------
        // Daha önce seçilmiş bir Kalem veya Grup varsa
        // yeni gelen verilerle tekrar çiz.
        // -------------------------------------------------

        if let selection =
            currentSelection {

            showSelection(
                selection
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

        // Son seçimi sakla.
        //
        // Böylece TRY <-> USD değişiminden sonra
        // aynı Kalem veya Grup yeniden çizilebilir.

        currentSelection =
            selection

        switch selection {

        // -------------------------------------------------
        // KALEM MODU
        // -------------------------------------------------

        case .single(
            let itemCode
        ):

            let selectedItems =
                financialItems.filter {
                    $0.itemCode ==
                        itemCode
                }

            guard
                !selectedItems.isEmpty
            else {

                print(
                    "Temel grafik: Seçilen kalem bulunamadı."
                )

                return
            }

            print(
                "Temel grafik seçimi: KALEM"
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

        // -------------------------------------------------
        // GRUP MODU
        // -------------------------------------------------

        case .group(
            let itemCodes
        ):

            guard
                let firstItemCode =
                    itemCodes.first
            else {

                print(
                    "Temel grafik: Grup içinde kalem yok."
                )

                return
            }

            // Grup kodundan doğrudan template bul.

            guard
                let template =
                    FundamentalChartTemplate.template(
                        containing:
                            firstItemCode
                    )
            else {

                print(
                    "Temel grafik: Grup için şablon bulunamadı."
                )

                return
            }

            let selectedItems =
                itemCodes.compactMap {
                    code in

                    financialItems.first {
                        $0.itemCode ==
                            code
                    }
                }

            guard
                !selectedItems.isEmpty
            else {

                print(
                    "Temel grafik: Grup kalemleri bulunamadı."
                )

                return
            }

            print(
                "Temel grafik seçimi: GRUP"
            )

            print(
                "Şablon: \(template.title)"
            )

            for item in selectedItems {

                print(
                    "\(item.itemCode) - \(item.name)"
                )
            }

            // Grup seçiminde standart show(...)
            // kullanılmıyor.
            //
            // Doğrudan grup template'i açılıyor.

            chartViewController.showGroup(
                template:
                    template,
                items:
                    selectedItems,
                periods:
                    financialPeriods
            )
        }
    }

    // MARK: - Alert

    private func showAlert(
        message:
            String
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


