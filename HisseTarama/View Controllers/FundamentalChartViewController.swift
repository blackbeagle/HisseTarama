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

    private let chartView:
        FundamentalBarChartView = {

        let chart =
            FundamentalBarChartView()

        chart.translatesAutoresizingMaskIntoConstraints =
            false

        return chart
    }()

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
            emptyStateLabel
        )

        view.addSubview(
            groupStateLabel
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
    }

    // MARK: - Public API
    //
    // Kalem modu.
    //
    // Mevcut davranış korunmuştur.
    //

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
    //
    // Grup modu.
    //
    // Şimdilik yalnızca şablon bilgisi
    // controller'a aktarılır.
    //
    // Özel grafik renderer'ları bir sonraki
    // aşamada burada devreye girecek.
    //

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

        updateDisplay()
    }

    // MARK: - Clear

    func clearChart() {

        items.removeAll()
        periods.removeAll()

        displayMode =
            .item

        chartView.setData(
            items:
                [],
            periods:
                []
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

        chartView.setData(
            items:
                [],
            periods:
                []
        )

        chartView.isHidden =
            true

        emptyStateLabel.isHidden =
            true

        groupStateLabel.isHidden =
            false

        titleLabel.stringValue =
            template.title

        subtitleLabel.stringValue =
            "\(template.group.title) • Grup görünümü"

        groupStateLabel.stringValue =
            groupPlaceholderText(
                template:
                    template
            )
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


