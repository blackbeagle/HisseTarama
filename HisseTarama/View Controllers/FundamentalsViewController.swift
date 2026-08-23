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

    // MARK: - UI

    private let separatorView: NSBox = {

        let box = NSBox()

        box.boxType = .separator

        box.translatesAutoresizingMaskIntoConstraints = false

        return box
    }()

    // MARK: - Lifecycle

    override func loadView() {

        view = NSView()
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        //test amaçlı bu satır. kaldırıalcak.
        //FinancialDataService.shared.testFetch()
        
        setupView()

        setupSidebar()

        setupChart()
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
                equalTo: view.leadingAnchor
            ),

            sidebarView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),

            sidebarView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),

            sidebarView.widthAnchor.constraint(
                equalToConstant: 250
            ),

            separatorView.leadingAnchor.constraint(
                equalTo: sidebarView.trailingAnchor
            ),

            separatorView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),

            separatorView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),

            separatorView.widthAnchor.constraint(
                equalToConstant: 1
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
                equalTo: separatorView.trailingAnchor
            ),

            chartView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),

            chartView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),

            chartView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
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

        // Önce eski finansal verileri temizle.
        financialItems.removeAll()
        financialPeriods.removeAll()

        // Eski grafiği temizle.
        chartViewController.clearChart()

        // Sidebar'daki hisseyi güncelle.
        sidebarViewController.updateStock(
            symbol: normalizedSymbol
        )

        // YENİ:
        // Seçilen hisse için finansal verileri çek.
        fetchFinancialData(
            for: normalizedSymbol
        )
    }

    

    // MARK: - Financial Data

    // MARK: - Financial Data

    private func fetchFinancialData(
        for symbol: String
    ) {

        print("================================")
        print("TEMEL VERİ ÇEKİMİ BAŞLADI")
        print("Hisse: \(symbol)")
        print("================================")

        let query = StockDataQuery(
            lastFinancialPeriod: nil,
            financialQuarterCount: 10,
            currency: .tryCurrency
        )

        FinancialDataService.shared.fetchFinancialStatements(
            companyCode: symbol,
            query: query
        ) { [weak self] result in

            DispatchQueue.main.async {

                guard let self = self else {
                    return
                }

                switch result {

                case .success(let statements):

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
                        items: statements.allItems,
                        periods: statements.periods
                    )

                case .failure(let error):

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
    
    // MARK: - Financial Data
    // MARK: - Financial Data

    // MARK: - Financial Data

    func updateFinancialData(
        items: [FinancialStatementItem],
        periods: [FinancialPeriod]
    ) {
        print(">>> updateFinancialData ÇAĞRILDI <<<")

        // ---------------------------------------------------------
        // Finansal verileri controller içinde sakla
        // ---------------------------------------------------------

        financialItems = items
        financialPeriods = periods

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
            items: financialItems
        )

        print(
            ">>> Fundamental sidebar finansal verilerle güncellendi <<<"
        )

        // ---------------------------------------------------------
        // Mevcut grafiği temizle
        // ---------------------------------------------------------

        chartViewController.clearChart()

        // ---------------------------------------------------------
        // Test amacıyla ilk finansal kalemi grafiğe gönder
        // ---------------------------------------------------------

        if !financialItems.isEmpty &&
            !financialPeriods.isEmpty {

            let firstItem = financialItems[0]

            print(
                "Test grafik kalemi: \(firstItem.itemCode) - \(firstItem.titleTR)"
            )

            chartViewController.show(
                items: [firstItem],
                periods: financialPeriods
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
        _ selection: FundamentalSelection
    ) {

        guard !financialItems.isEmpty,
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

                    $0.itemCode == itemCode
                }

        case .group(
            let itemCodes
        ):

            selectedItems =
                itemCodes.compactMap {

                    code in

                    financialItems.first {

                        $0.itemCode == code
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
            items: selectedItems,
            periods: financialPeriods
        )
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

