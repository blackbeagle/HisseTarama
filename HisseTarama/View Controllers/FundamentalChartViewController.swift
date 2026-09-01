import Cocoa

final class FundamentalChartViewController: NSViewController {

    // MARK: - Data

    private var items: [FinancialStatementItem] = []
    private var periods: [FinancialPeriod] = []

    // MARK: - UI

    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Finansal Grafik")
        label.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let chartView: FundamentalBarChartView = {
        let chart = FundamentalBarChartView()
        chart.translatesAutoresizingMaskIntoConstraints = false
        return chart
    }()

    private let emptyStateLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Görüntülenecek finansal veri yok.")
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 15)
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
        updateEmptyState()
    }

    // MARK: - Setup

    private func setupView() {
        view.wantsLayer = true

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(chartView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
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

            chartView.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor,
                constant: 16
            ),
            chartView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            chartView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            chartView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -20
            ),

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
            )
        ])
    }

    // MARK: - Public API

    func show(
        items: [FinancialStatementItem],
        periods: [FinancialPeriod]
    ) {
        self.items = items
        self.periods = periods
        updateChart()
    }

    func setCurrency(isUSD: Bool) {
        chartView.setCurrency(isUSD: isUSD)
    }

    func clearChart() {
        items.removeAll()
        periods.removeAll()

        titleLabel.stringValue = "Finansal Grafik"
        subtitleLabel.stringValue = ""

        chartView.setData(
            items: [],
            periods: []
        )

        updateEmptyState()
    }

    // MARK: - Update

    private func updateChart() {
        guard !items.isEmpty, !periods.isEmpty else {
            clearChart()
            return
        }

        updateTitle()
        updateSubtitle()

        chartView.setData(
            items: items,
            periods: periods
        )

        updateEmptyState()
    }

    private func updateTitle() {
        if items.count == 1 {
            titleLabel.stringValue = items[0].name
        } else {
            titleLabel.stringValue = "Finansal Karşılaştırma"
        }
    }

    private func updateSubtitle() {
        if items.count == 1 {
            subtitleLabel.stringValue =
                "\(items[0].itemCode) • \(periods.count) dönem"
        } else {
            let names = items
                .map { $0.name }
                .joined(separator: " + ")

            subtitleLabel.stringValue =
                "\(names) • \(periods.count) dönem"
        }
    }

    private func updateEmptyState() {
        let hasData = !items.isEmpty && !periods.isEmpty

        chartView.isHidden = !hasData
        emptyStateLabel.isHidden = hasData
    }
}


