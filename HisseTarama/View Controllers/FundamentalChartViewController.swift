import Cocoa

final class FundamentalChartViewController: NSViewController {

    // MARK: - Display Mode

    private enum DisplayMode {

        case item

        case group(template: FundamentalChartTemplate)
    }

    private var displayMode: DisplayMode = .item

    // MARK: - Data

    private var items: [FinancialStatementItem] = []

    private var periods: [FinancialPeriod] = []

    // MARK: - Currency

    private var isUSDMode = false

    // MARK: - UI

    private let titleLabel: NSTextField = {

        let label = NSTextField(
            labelWithString: "Finansal Grafik"
        )

        label.font = NSFont.systemFont(
            ofSize: 18,
            weight: .semibold
        )

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let subtitleLabel: NSTextField = {

        let label = NSTextField(
            labelWithString: ""
        )

        label.font = NSFont.systemFont(
            ofSize: 12
        )

        label.textColor = .secondaryLabelColor

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Standard Chart

    private let chartView: StandartBarChartRenderer = {

        let chart = StandartBarChartRenderer()

        chart.translatesAutoresizingMaskIntoConstraints = false

        return chart
    }()

    // MARK: - Group Charts Container

    private let groupChartsContainer: NSView = {

        let view = NSView()

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    // MARK: - Sales Charts

    private let revenueCostChartView: FundamentalChartHostView = {

        let view = FundamentalChartHostView(
            renderer: RevenueCostChartRenderer()
        )

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private let domesticExportSalesChart: DomesticExportSalesChartRenderer = {

        let chart = DomesticExportSalesChartRenderer()

        chart.translatesAutoresizingMaskIntoConstraints = false

        return chart
    }()

    private let lowerRevenueCostChartView: FundamentalChartHostView = {

        let view = FundamentalChartHostView(
            renderer: RevenueCostChartRenderer()
        )

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    // MARK: - Empty State

    private let emptyStateLabel: NSTextField = {

        let label = NSTextField(
            labelWithString:
                "Görüntülenecek finansal veri yok."
        )

        label.alignment = .center

        label.font = NSFont.systemFont(
            ofSize: 15
        )

        label.textColor = .secondaryLabelColor

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Group State Label

    private let groupStateLabel: NSTextField = {

        let label = NSTextField(
            labelWithString: ""
        )

        label.alignment = .center

        label.font = NSFont.systemFont(
            ofSize: 15,
            weight: .medium
        )

        label.textColor = .secondaryLabelColor

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Lifecycle

    override func loadView() {

        view = NSView()
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setupView()

        updateDisplay()
    }

    // MARK: - Setup

    private func setupView() {

        view.wantsLayer = true

        view.addSubview(titleLabel)

        view.addSubview(subtitleLabel)

        view.addSubview(chartView)

        view.addSubview(groupChartsContainer)

        view.addSubview(emptyStateLabel)

        view.addSubview(groupStateLabel)

        // -------------------------------------------------
        // Group chart container
        // -------------------------------------------------

        groupChartsContainer.addSubview(
            revenueCostChartView
        )

        groupChartsContainer.addSubview(
            domesticExportSalesChart
        )

        groupChartsContainer.addSubview(
            lowerRevenueCostChartView
        )

        NSLayoutConstraint.activate([

            // MARK: Başlık

            titleLabel.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 16
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),

            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -20
            ),

            // MARK: Alt başlık

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 4
            ),

            subtitleLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),

            subtitleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -20
            ),

            // MARK: - Standart grafik

            chartView.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor,
                constant: 180
            ),

            chartView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 15
            ),

            chartView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -15
            ),

            chartView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -180
            ),

            // MARK: Grup grafik alanı

            groupChartsContainer.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor,
                constant: 12
            ),

            groupChartsContainer.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),

            groupChartsContainer.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),

            groupChartsContainer.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -20
            ),

            // =================================================
            // ÜST SOL
            // Revenue / Cost
            // =================================================

            revenueCostChartView.leadingAnchor.constraint(
                equalTo: groupChartsContainer.leadingAnchor
            ),

            revenueCostChartView.trailingAnchor.constraint(
                equalTo: groupChartsContainer.centerXAnchor,
                constant: -6
            ),

            revenueCostChartView.topAnchor.constraint(
                equalTo: groupChartsContainer.topAnchor
            ),

            revenueCostChartView.bottomAnchor.constraint(
                equalTo: groupChartsContainer.centerYAnchor,
                constant: -6
            ),

            // =================================================
            // ÜST SAĞ
            // Yurtiçi / Yurtdışı
            // =================================================

            domesticExportSalesChart.leadingAnchor.constraint(
                equalTo: groupChartsContainer.centerXAnchor,
                constant: 6
            ),

            domesticExportSalesChart.trailingAnchor.constraint(
                equalTo: groupChartsContainer.trailingAnchor
            ),

            domesticExportSalesChart.topAnchor.constraint(
                equalTo: groupChartsContainer.topAnchor
            ),

            domesticExportSalesChart.bottomAnchor.constraint(
                equalTo: groupChartsContainer.centerYAnchor,
                constant: -6
            ),

            // =================================================
            // ALT
            // Revenue / Cost
            // =================================================

            lowerRevenueCostChartView.leadingAnchor.constraint(
                equalTo: groupChartsContainer.leadingAnchor
            ),

            lowerRevenueCostChartView.trailingAnchor.constraint(
                equalTo: groupChartsContainer.trailingAnchor
            ),

            lowerRevenueCostChartView.topAnchor.constraint(
                equalTo: groupChartsContainer.centerYAnchor,
                constant: 6
            ),

            lowerRevenueCostChartView.bottomAnchor.constraint(
                equalTo: groupChartsContainer.bottomAnchor
            ),

            // MARK: Boş durum

            emptyStateLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            emptyStateLabel.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),

            emptyStateLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 20
            ),

            emptyStateLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -20
            ),

            // MARK: Grup durum alanı

            groupStateLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            groupStateLabel.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),

            groupStateLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 20
            ),

            groupStateLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -20
            )
        ])

        groupChartsContainer.isHidden = true

        revenueCostChartView.isHidden = false

        domesticExportSalesChart.isHidden = false

        lowerRevenueCostChartView.isHidden = false
    }

    // MARK: - Public API

    // Kalem modu.
    // Mevcut davranış korunmuştur.

    func show(
        items: [FinancialStatementItem],
        periods: [FinancialPeriod]
    ) {

        self.displayMode = .item

        self.items = items

        self.periods = periods

        updateDisplay()
    }

    // MARK: - Group API

    func showGroup(
        template: FundamentalChartTemplate,
        items: [FinancialStatementItem],
        periods: [FinancialPeriod]
    ) {

        self.displayMode = .group(
            template: template
        )

        self.items = items

        self.periods = periods

        updateDisplay()
    }

    // MARK: - Currency

    func setCurrency(
        isUSD: Bool
    ) {

        self.isUSDMode = isUSD

        chartView.setCurrency(
            isUSD: isUSD
        )

        revenueCostChartView.setCurrency(
            isUSD: isUSD
        )

        lowerRevenueCostChartView.setCurrency(
            isUSD: isUSD
        )

        domesticExportSalesChart.setCurrency(
            isUSD: isUSD
        )

        updateDisplay()
    }

    // MARK: - Clear

    func clearChart() {

        items.removeAll()

        periods.removeAll()

        displayMode = .item

        chartView.clear()

        revenueCostChartView.clear()

        lowerRevenueCostChartView.clear()

        updateDisplay()
    }

    // MARK: - Display

    private func updateDisplay() {

        switch displayMode {

        case .item:

            updateItemDisplay()

        case .group(let template):

            updateGroupDisplay(
                template: template
            )
        }
    }

    // MARK: - Item Display

    private func updateItemDisplay() {

        groupStateLabel.isHidden = true

        groupChartsContainer.isHidden = true

        guard
            !items.isEmpty,
            !periods.isEmpty
        else {

            chartView.clear()

            titleLabel.stringValue =
                "Finansal Grafik"

            subtitleLabel.stringValue = ""

            chartView.isHidden = true

            emptyStateLabel.isHidden = false

            return
        }

        // -------------------------------------------------
        // StandartBarChartRenderer için veri hazırlanıyor.
        //
        // Şimdilik yalnızca tek finansal kalem
        // standart grafik olarak gösteriliyor.
        // -------------------------------------------------

        var chartData:
            [StandartBarChartRenderer.DataPoint] = []

        if items.count == 1 {

            let item = items[0]

            for period in periods {

                let value =
                    item.value(
                        for: period
                    ) ?? 0

                chartData.append(

                    StandartBarChartRenderer.DataPoint(

                        periodTitle:
                            period.title,

                        value:
                            value
                    )
                )
            }
        }

        chartView.setData(
            chartData
        )

        chartView.setCurrency(
            isUSD: isUSDMode
        )
        
        if items.count == 1 {
            chartView.setTitle(
                items[0].displayTitle
            )
        }

        updateItemTitle()

        updateItemSubtitle()

        chartView.isHidden = false

        emptyStateLabel.isHidden = true
    }

    // MARK: - Group Display

    private func updateGroupDisplay(
        template: FundamentalChartTemplate
    ) {

        chartView.isHidden = true

        emptyStateLabel.isHidden = true

        groupStateLabel.isHidden = true

        groupChartsContainer.isHidden = false

        titleLabel.stringValue =
            template.title

        subtitleLabel.stringValue =
            "\(template.group.title) • Grup görünümü"

        switch template.id {

        case "sales":

            showSalesGroup()

        default:

            groupChartsContainer.isHidden = true

            groupStateLabel.isHidden = false

            groupStateLabel.stringValue =
                groupPlaceholderText(
                    template: template
                )
        }
    }

    // MARK: - Sales Group

    private func showSalesGroup() {

        // -------------------------------------------------
        // 3C - Satış Gelirleri
        // -------------------------------------------------

        let revenueItem =
            items.first {
                $0.itemCode == "3C"
            }

        // -------------------------------------------------
        // 3CA - Satışların Maliyeti
        // -------------------------------------------------

        let costItem =
            items.first {
                $0.itemCode == "3CA"
            }

        // -------------------------------------------------
        // 4BC - Yurtiçi Satışlar
        // -------------------------------------------------

        let domesticItem =
            items.first {
                $0.itemCode == "4BC"
            }

        // -------------------------------------------------
        // 4BD - Yurtdışı Satışlar
        // -------------------------------------------------

        let exportItem =
            items.first {
                $0.itemCode == "4BD"
            }

        // -------------------------------------------------
        // Revenue / Cost verisi
        // -------------------------------------------------

        var revenueCostData:
            [RevenueCostChartRenderer.DataPoint] = []

        if
            let revenueItem = revenueItem,
            let costItem = costItem
        {

            for period in periods {

                let revenue =
                    revenueItem.value(
                        for: period
                    ) ?? 0

                let cost =
                    costItem.value(
                        for: period
                    ) ?? 0

                revenueCostData.append(

                    RevenueCostChartRenderer.DataPoint(

                        periodTitle:
                            period.title,

                        revenue:
                            revenue,

                        cost:
                            cost
                    )
                )
            }
        }

        // -------------------------------------------------
        // Üst Revenue / Cost
        // -------------------------------------------------

        revenueCostChartView.setData(
            revenueCostData
        )

        revenueCostChartView.setCurrency(
            isUSD: isUSDMode
        )

        // -------------------------------------------------
        // Alt Revenue / Cost
        //
        // Aynı veri.
        // Ama farklı boyuttaki host üzerinde test edilir.
        // -------------------------------------------------

        lowerRevenueCostChartView.setData(
            revenueCostData
        )

        lowerRevenueCostChartView.setCurrency(
            isUSD: isUSDMode
        )

        // -------------------------------------------------
        // Yurtiçi / Yurtdışı
        // -------------------------------------------------

        if
            let domesticItem = domesticItem,
            let exportItem = exportItem
        {

            domesticExportSalesChart.setData(
                domesticItem: domesticItem,
                exportItem: exportItem,
                periods: periods
            )
        }

        domesticExportSalesChart.setCurrency(
            isUSD: isUSDMode
        )

        // -------------------------------------------------
        // Üç grafik görünür.
        // -------------------------------------------------

        revenueCostChartView.isHidden = false

        domesticExportSalesChart.isHidden = false

        lowerRevenueCostChartView.isHidden = false
    }

    // MARK: - Group Placeholder

    private func groupPlaceholderText(
        template: FundamentalChartTemplate
    ) -> String {

        switch template.id {

        case "sales":

            return
                "Satışlar grup şablonu hazırlanıyor..."

        default:

            return
                "\(template.title) grup şablonu hazırlanıyor..."
        }
    }

    // MARK: - Item Title

    private func updateItemTitle() {

        guard !items.isEmpty else {

            titleLabel.stringValue =
                "Finansal Grafik"

            return
        }

        if items.count == 1 {

            titleLabel.stringValue =
                items[0].displayTitle

        } else {

            titleLabel.stringValue =
                "Finansal Grafik"
        }
    }

    // MARK: - Item Subtitle

    private func updateItemSubtitle() {

        guard !items.isEmpty else {

            subtitleLabel.stringValue = ""

            return
        }

        if items.count == 1 {

            subtitleLabel.stringValue =
                items[0].itemCode

        } else {

            subtitleLabel.stringValue =
                "\(items.count) finansal kalem"
        }
    }
}
