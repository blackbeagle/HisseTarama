import Cocoa

final class FundamentalChartViewController: NSViewController {

    // MARK: - Display Mode

    private enum DisplayMode {

        case item

        case group(
            template:
                FundamentalChartTemplate
        )
    }

    private var displayMode:
        DisplayMode = .item

    // MARK: - Data

    private var items:
        [FinancialStatementItem] = []

    private var periods:
        [FinancialPeriod] = []

    // MARK: - Currency

    private var isUSDMode =
        false

    // MARK: - UI

    private let titleLabel: NSTextField = {

        let label =
            NSTextField(
                labelWithString:
                    "Finansal Grafik"
            )

        label.font =
            NSFont.systemFont(
                ofSize:
                    18,
                weight:
                    .semibold
            )

        label.translatesAutoresizingMaskIntoConstraints =
            false

        return label
    }()

    private let subtitleLabel: NSTextField = {

        let label =
            NSTextField(
                labelWithString:
                    ""
            )

        label.font =
            NSFont.systemFont(
                ofSize:
                    12
            )

        label.textColor =
            .secondaryLabelColor

        label.translatesAutoresizingMaskIntoConstraints =
            false

        return label
    }()

    // MARK: - Standard Chart

    private let chartView:
        FundamentalBarChartView = {

        let chart =
            FundamentalBarChartView()

        chart.translatesAutoresizingMaskIntoConstraints =
            false

        return chart
    }()

    // MARK: - Group Charts Container

    private let groupChartsContainer: NSView = {

        let view =
            NSView()

        view.translatesAutoresizingMaskIntoConstraints =
            false

        return view
    }()

    // MARK: - Sales Charts

    private let revenueCostHostView:
        RevenueCostHostView = {

        let view =
            RevenueCostHostView()

        view.translatesAutoresizingMaskIntoConstraints =
            false

        return view
    }()

    private let domesticExportSalesChart:
        DomesticExportSalesChartRenderer = {

        let chart =
            DomesticExportSalesChartRenderer()

        chart.translatesAutoresizingMaskIntoConstraints =
            false

        return chart
    }()

    // MARK: - Empty State

    private let emptyStateLabel: NSTextField = {

        let label =
            NSTextField(
                labelWithString:
                    "Görüntülenecek finansal veri yok."
            )

        label.alignment =
            .center

        label.font =
            NSFont.systemFont(
                ofSize:
                    15
            )

        label.textColor =
            .secondaryLabelColor

        label.translatesAutoresizingMaskIntoConstraints =
            false

        return label
    }()

    // MARK: - Group State Label

    private let groupStateLabel: NSTextField = {

        let label =
            NSTextField(
                labelWithString:
                    ""
            )

        label.alignment =
            .center

        label.font =
            NSFont.systemFont(
                ofSize:
                    15,
                weight:
                    .medium
            )

        label.textColor =
            .secondaryLabelColor

        label.translatesAutoresizingMaskIntoConstraints =
            false

        return label
    }()

    // MARK: - Lifecycle

    override func loadView() {

        view =
            NSView()
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setupView()

        updateDisplay()
    }

    // MARK: - Setup

    private func setupView() {

        view.wantsLayer =
            true

        view.addSubview(
            titleLabel
        )

        view.addSubview(
            subtitleLabel
        )

        view.addSubview(
            chartView
        )

        view.addSubview(
            groupChartsContainer
        )

        view.addSubview(
            emptyStateLabel
        )

        view.addSubview(
            groupStateLabel
        )

        // -------------------------------------------------
        // Group chart container
        // -------------------------------------------------

        groupChartsContainer.addSubview(
            revenueCostHostView
        )

        groupChartsContainer.addSubview(
            domesticExportSalesChart
        )

        NSLayoutConstraint.activate([

            // MARK: Başlık

            titleLabel.topAnchor.constraint(
                equalTo:
                    view.topAnchor,
                constant:
                    16
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor,
                constant:
                    20
            ),

            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    view.trailingAnchor,
                constant:
                    -20
            ),

            // MARK: Alt başlık

            subtitleLabel.topAnchor.constraint(
                equalTo:
                    titleLabel.bottomAnchor,
                constant:
                    4
            ),

            subtitleLabel.leadingAnchor.constraint(
                equalTo:
                    titleLabel.leadingAnchor
            ),

            subtitleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    view.trailingAnchor,
                constant:
                    -20
            ),

            // MARK: Standart grafik

            chartView.topAnchor.constraint(
                equalTo:
                    subtitleLabel.bottomAnchor,
                constant:
                    16
            ),

            chartView.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor,
                constant:
                    20
            ),

            chartView.trailingAnchor.constraint(
                equalTo:
                    view.trailingAnchor,
                constant:
                    -20
            ),

            chartView.bottomAnchor.constraint(
                equalTo:
                    view.bottomAnchor,
                constant:
                    -20
            ),

            // MARK: Grup grafik alanı

            groupChartsContainer.topAnchor.constraint(
                equalTo:
                    subtitleLabel.bottomAnchor,
                constant:
                    12
            ),

            groupChartsContainer.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor,
                constant:
                    20
            ),

            groupChartsContainer.trailingAnchor.constraint(
                equalTo:
                    view.trailingAnchor,
                constant:
                    -20
            ),

            groupChartsContainer.bottomAnchor.constraint(
                equalTo:
                    view.bottomAnchor,
                constant:
                    -20
            ),

            // MARK: Revenue / Cost

            revenueCostHostView.leadingAnchor.constraint(
                equalTo:
                    groupChartsContainer.leadingAnchor
            ),

            revenueCostHostView.trailingAnchor.constraint(
                equalTo:
                    groupChartsContainer.trailingAnchor
            ),

            revenueCostHostView.topAnchor.constraint(
                equalTo:
                    groupChartsContainer.topAnchor
            ),

            revenueCostHostView.bottomAnchor.constraint(
                equalTo:
                    groupChartsContainer.centerYAnchor
            ),

            // MARK: Yurtiçi / Yurtdışı

            domesticExportSalesChart.leadingAnchor.constraint(
                equalTo:
                    groupChartsContainer.leadingAnchor
            ),

            domesticExportSalesChart.trailingAnchor.constraint(
                equalTo:
                    groupChartsContainer.trailingAnchor
            ),

            domesticExportSalesChart.topAnchor.constraint(
                equalTo:
                    groupChartsContainer.centerYAnchor
            ),

            domesticExportSalesChart.bottomAnchor.constraint(
                equalTo:
                    groupChartsContainer.bottomAnchor
            ),

            // MARK: Boş durum

            emptyStateLabel.centerXAnchor.constraint(
                equalTo:
                    view.centerXAnchor
            ),

            emptyStateLabel.centerYAnchor.constraint(
                equalTo:
                    view.centerYAnchor
            ),

            emptyStateLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo:
                    view.leadingAnchor,
                constant:
                    20
            ),

            emptyStateLabel.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    view.trailingAnchor,
                constant:
                    -20
            ),

            // MARK: Grup durum alanı

            groupStateLabel.centerXAnchor.constraint(
                equalTo:
                    view.centerXAnchor
            ),

            groupStateLabel.centerYAnchor.constraint(
                equalTo:
                    view.centerYAnchor
            ),

            groupStateLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo:
                    view.leadingAnchor,
                constant:
                    20
            ),

            groupStateLabel.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    view.trailingAnchor,
                constant:
                    -20
            )
        ])

        groupChartsContainer.isHidden =
            true

        revenueCostHostView.isHidden =
            false

        domesticExportSalesChart.isHidden =
            false
    }

    // MARK: - Public API

    // Kalem modu.

    // Mevcut davranış korunmuştur.

    func show(
        items:
            [FinancialStatementItem],
        periods:
            [FinancialPeriod]
    ) {

        self.displayMode =
            .item

        self.items =
            items

        self.periods =
            periods

        updateDisplay()
    }

    // MARK: - Group API

    func showGroup(
        template:
            FundamentalChartTemplate,
        items:
            [FinancialStatementItem],
        periods:
            [FinancialPeriod]
    ) {

        self.displayMode =
            .group(
                template:
                    template
            )

        self.items =
            items

        self.periods =
            periods

        updateDisplay()
    }

    // MARK: - Currency

    func setCurrency(
        isUSD:
            Bool
    ) {

        self.isUSDMode =
            isUSD

        chartView.setCurrency(
            isUSD:
                isUSD
        )

        revenueCostHostView.setCurrency(
            isUSD:
                isUSD
        )

        domesticExportSalesChart.setCurrency(
            isUSD:
                isUSD
        )

        updateDisplay()
    }

    // MARK: - Clear

    func clearChart() {

        items.removeAll()
        periods.removeAll()
        displayMode = .item

        chartView.setData(
            items: [],
            periods: []
        )

        revenueCostHostView.setData(
            data: []
        )

        updateDisplay()
    }

    // MARK: - Display

    private func updateDisplay() {

        switch displayMode {

        case .item:

            updateItemDisplay()

        case .group(
            let template
        ):

            updateGroupDisplay(
                template:
                    template
            )
        }
    }

    // MARK: - Item Display

    private func updateItemDisplay() {

        groupStateLabel.isHidden =
            true

        groupChartsContainer.isHidden =
            true

        guard
            !items.isEmpty,
            !periods.isEmpty
        else {

            chartView.setData(
                items:
                    [],
                periods:
                    []
            )

            titleLabel.stringValue =
                "Finansal Grafik"

            subtitleLabel.stringValue =
                ""

            chartView.isHidden =
                true

            emptyStateLabel.isHidden =
                false

            return
        }

        chartView.setData(
            items:
                items,
            periods:
                periods
        )

        chartView.setCurrency(
            isUSD:
                isUSDMode
        )

        updateItemTitle()

        updateItemSubtitle()

        chartView.isHidden =
            false

        emptyStateLabel.isHidden =
            true
    }

    // MARK: - Group Display

    private func updateGroupDisplay(
        template:
            FundamentalChartTemplate
    ) {

        chartView.isHidden =
            true

        emptyStateLabel.isHidden =
            true

        groupStateLabel.isHidden =
            true

        groupChartsContainer.isHidden =
            false

        titleLabel.stringValue =
            template.title

        subtitleLabel.stringValue =
            "\(template.group.title) • Grup görünümü"

        switch template.id {

        case "sales":

            showSalesGroup()

        default:

            groupChartsContainer.isHidden =
                true

            groupStateLabel.isHidden =
                false

            groupStateLabel.stringValue =
                groupPlaceholderText(
                    template:
                        template
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
        // Grafik 1
        //
        // Satış Gelirleri / Satışların Maliyeti /
        // Brüt Kâr
        // -------------------------------------------------

        var revenueCostData:
            [RevenueCostChartRenderer.DataPoint] = []

        if
            let revenueItem =
                revenueItem,
            let costItem =
                costItem
        {

            for period in periods {

                let revenue =
                    revenueItem.value(
                        for:
                            period
                    ) ?? 0

                let cost =
                    costItem.value(
                        for:
                            period
                    ) ?? 0

                revenueCostData.append(

                    RevenueCostChartRenderer.DataPoint(
                        revenue:
                            revenue,
                        cost:
                            cost
                    )
                )
            }
        }

        revenueCostHostView.setData(
            data:
                revenueCostData
        )

        revenueCostHostView.setCurrency(
            isUSD:
                isUSDMode
        )

        // -------------------------------------------------
        // Grafik 2
        //
        // Yurtiçi / Yurtdışı Satışlar
        // -------------------------------------------------

        if
            let domesticItem =
                domesticItem,
            let exportItem =
                exportItem
        {

            domesticExportSalesChart.setData(
                domesticItem:
                    domesticItem,
                exportItem:
                    exportItem,
                periods:
                    periods
            )

        }

        domesticExportSalesChart.setCurrency(
            isUSD:
                isUSDMode
        )

        // -------------------------------------------------
        // Şimdilik iki grafikli layout.
        // -------------------------------------------------

        revenueCostHostView.isHidden =
            false

        domesticExportSalesChart.isHidden =
            false
    }

    // MARK: - Group Placeholder

    private func groupPlaceholderText(
        template:
            FundamentalChartTemplate
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

        guard
            !items.isEmpty
        else {

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

        guard
            !items.isEmpty
        else {

            subtitleLabel.stringValue =
                ""

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

// MARK: - Revenue Cost Host View

private final class RevenueCostHostView: NSView {

    private let renderer =
        RevenueCostChartRenderer()

    private var data:
        [RevenueCostChartRenderer.DataPoint] = []

    private var isUSDMode =
        false

    override init(
        frame frameRect: NSRect
    ) {

        super.init(
            frame:
                frameRect
        )

        wantsLayer =
            true
    }

    required init?(
        coder:
            NSCoder
    ) {

        super.init(
            coder:
                coder
        )

        wantsLayer =
            true
    }

    // MARK: - Data

    func setData(
        data:
            [RevenueCostChartRenderer.DataPoint]
    ) {

        self.data =
            data

        needsDisplay =
            true
    }

    // MARK: - Currency

    func setCurrency(
        isUSD:
            Bool
    ) {

        self.isUSDMode =
            isUSD

        needsDisplay =
            true
    }

    // MARK: - Drawing

    override func draw(
        _ dirtyRect: NSRect
    ) {

        super.draw(
            dirtyRect
        )

        guard
            !data.isEmpty
        else {
            return
        }

        let chartRect =
            bounds.insetBy(
                dx:
                    30,
                dy:
                    35
            )

        let maximumValue =
            data.reduce(
                0
            ) {

                partialResult,
                dataPoint in

                max(
                    partialResult,
                    max(
                        0,
                        dataPoint.revenue
                    )
                )
            }

        guard
            maximumValue > 0
        else {
            return
        }

        let count =
            data.count

        guard count > 0 else {
            return
        }

        let availableWidth =
            chartRect.width

        let barSpacing =
            min(
                22,
                max(
                    5,
                    availableWidth /
                    CGFloat(
                        count * 5
                    )
                )
            )

        let barWidth =
            max(
                12,
                min(
                    48,
                    (
                        availableWidth -
                        CGFloat(
                            max(
                                0,
                                count - 1
                            )
                        ) *
                        barSpacing
                    ) /
                    CGFloat(count)
                )
            )

        renderer.draw(
            data:
                data,
            in:
                chartRect,
            barWidth:
                barWidth,
            barSpacing:
                barSpacing,
            maximumValue:
                maximumValue
        )

        _ = isUSDMode
    }
}


