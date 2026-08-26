import Cocoa

enum ChartPeriod {
    case daily
    case weekly
}

enum ChartCurrency {
    case tryCurrency
    case usd
}

class ChartDetailViewController: NSViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var chartContainerView: NSView!

    // MARK: - Properties

    private var chartView: CandlestickChartView?
    private var currentCandlesticks: [Candlestick] = []

    var stockData: [Value]?
    var dateAndPrices: [(date: Date, price: Double)] = []
    var dataString: String?

    private var activeSMAs: [Int: [Double?]] = [:]
    private var smaButtons: [Int: NSButton] = [:]
    private var smaContainerView: NSView?

    private var chartPeriod: ChartPeriod = .daily
    private var chartCurrency: ChartCurrency = .tryCurrency

    private var dailyCandlesticks: [Candlestick] = []

    // -------------------------------------------------
    // Veri çekme durumu
    // -------------------------------------------------

    private var currentFetchID = UUID()

    private var loadingOverlay: NSView?
    private var loadingIndicator: NSProgressIndicator?
    private var loadingLabel: NSTextField?

    // Günlük ve haftalık görünüm
    private let dailyVisibleBarCount = 150
    private let weeklyVisibleBarCount = 80

    // MARK: - Period Control

    private let periodControl: NSSegmentedControl = {

        let control = NSSegmentedControl(
            labels: ["Günlük", "Haftalık"],
            trackingMode: .selectOne,
            target: nil,
            action: nil
        )

        control.selectedSegment = 0
        control.translatesAutoresizingMaskIntoConstraints = false

        return control
    }()
    
    // MARK: - Data Fetch Result

    var onDataFetchCompleted:
        ((String, Bool) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {

        super.viewDidLoad()

        setupView()
        setupUI()
        setupChartView()
        setupGlobalSelectionObservers()
    }

    // MARK: - Global Selection

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

    private func setupView() {

        view.wantsLayer = true

        view.layer?.backgroundColor =
            NSColor.windowBackgroundColor.cgColor

        view.autoresizingMask = [
            .width,
            .height
        ]

        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLayout() {

        super.viewDidLayout()

        chartView?.needsDisplay = true
    }

    // MARK: - Setup UI

    private func setupUI() {

        chartContainerView.translatesAutoresizingMaskIntoConstraints = false

        // -------------------------------------------------
        // Indicator Button
        // -------------------------------------------------

        let indicatorButton = NSButton()

        indicatorButton.title =
            "Ortalama/Gösterge Ekle"

        indicatorButton.bezelStyle = .rounded
        indicatorButton.target = self
        indicatorButton.action = #selector(openIndicatorPopup)
        indicatorButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(indicatorButton)

        // -------------------------------------------------
        // Period Control
        // -------------------------------------------------

        view.addSubview(periodControl)

        periodControl.target = self
        periodControl.action = #selector(periodChanged)

        // -------------------------------------------------
        // SMA Container
        // -------------------------------------------------

        let smaContainerView = NSView()

        smaContainerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(smaContainerView)

        NSLayoutConstraint.activate([

            // -------------------------------------------------
            // Indicator Button
            // -------------------------------------------------

            indicatorButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),

            indicatorButton.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 40
            ),

            // -------------------------------------------------
            // Period Control
            // -------------------------------------------------

            periodControl.leadingAnchor.constraint(
                equalTo: indicatorButton.trailingAnchor,
                constant: 8
            ),

            periodControl.centerYAnchor.constraint(
                equalTo: indicatorButton.centerYAnchor
            ),

            periodControl.widthAnchor.constraint(
                equalToConstant: 150
            ),

            // -------------------------------------------------
            // SMA Container
            // -------------------------------------------------

            smaContainerView.leadingAnchor.constraint(
                equalTo: periodControl.trailingAnchor,
                constant: 10
            ),

            smaContainerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),

            smaContainerView.centerYAnchor.constraint(
                equalTo: indicatorButton.centerYAnchor
            ),

            smaContainerView.heightAnchor.constraint(
                equalToConstant: 25
            ),

            // -------------------------------------------------
            // Chart
            // -------------------------------------------------

            chartContainerView.topAnchor.constraint(
                equalTo: indicatorButton.bottomAnchor,
                constant: 20
            ),

            chartContainerView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),

            chartContainerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),

            chartContainerView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -20
            )
        ])

        self.smaContainerView =
            smaContainerView
    }

    // MARK: - Chart View

    private func setupChartView() {

        chartView = CandlestickChartView()

        guard let chartView = chartView else {
            return
        }

        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.wantsLayer = true

        chartView.layer?.backgroundColor =
            NSColor.controlBackgroundColor.cgColor

        chartContainerView.addSubview(chartView)

        NSLayoutConstraint.activate([

            chartView.topAnchor.constraint(
                equalTo: chartContainerView.topAnchor
            ),

            chartView.leadingAnchor.constraint(
                equalTo: chartContainerView.leadingAnchor
            ),

            chartView.trailingAnchor.constraint(
                equalTo: chartContainerView.trailingAnchor
            ),

            chartView.bottomAnchor.constraint(
                equalTo: chartContainerView.bottomAnchor
            )
        ])

        chartView.setVisibleBarCount(
            dailyVisibleBarCount
        )
    }

    // MARK: - Loading Overlay

    private func showLoadingOverlay(
        for symbol: String
    ) {

        hideLoadingOverlay()

        let overlay = NSView()

        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.wantsLayer = true

        overlay.layer?.backgroundColor =
            NSColor.windowBackgroundColor
                .withAlphaComponent(0.78)
                .cgColor

        chartContainerView.addSubview(overlay)

        NSLayoutConstraint.activate([

            overlay.leadingAnchor.constraint(
                equalTo: chartContainerView.leadingAnchor
            ),

            overlay.trailingAnchor.constraint(
                equalTo: chartContainerView.trailingAnchor
            ),

            overlay.topAnchor.constraint(
                equalTo: chartContainerView.topAnchor
            ),

            overlay.bottomAnchor.constraint(
                equalTo: chartContainerView.bottomAnchor
            )
        ])

        // -------------------------------------------------
        // Indicator
        // -------------------------------------------------

        let indicator = NSProgressIndicator()

        indicator.style = .spinning
        indicator.controlSize = .regular
        indicator.isIndeterminate = true
        indicator.translatesAutoresizingMaskIntoConstraints = false

        indicator.startAnimation(nil)

        overlay.addSubview(indicator)

        // -------------------------------------------------
        // Label
        // -------------------------------------------------

        let label = NSTextField(
            labelWithString:
                "\(symbol) verileri getiriliyor..."
        )

        label.font =
            NSFont.systemFont(
                ofSize: 14,
                weight: .medium
            )

        label.textColor =
            NSColor.labelColor

        label.alignment = .center

        label.translatesAutoresizingMaskIntoConstraints = false

        overlay.addSubview(label)

        NSLayoutConstraint.activate([

            indicator.centerXAnchor.constraint(
                equalTo: overlay.centerXAnchor
            ),

            indicator.centerYAnchor.constraint(
                equalTo: overlay.centerYAnchor,
                constant: -12
            ),

            label.centerXAnchor.constraint(
                equalTo: overlay.centerXAnchor
            ),

            label.topAnchor.constraint(
                equalTo: indicator.bottomAnchor,
                constant: 12
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

    // MARK: - Actions

    @objc private func globalCurrencyChanged(
        _ notification: Notification
    ) {

        switch AppSelectionState.shared.selectedCurrency {

        case .tryCurrency:
            chartCurrency = .tryCurrency

        case .usd:
            chartCurrency = .usd
        }

        guard !dailyCandlesticks.isEmpty else {
            return
        }

        if chartCurrency == .usd {

            let hasUSDData =
                dailyCandlesticks.contains {

                    $0.usdMax != nil ||
                    $0.usdMin != nil ||
                    $0.usdWeightedAverage != nil
                }

            guard hasUSDData else {

                chartCurrency = .tryCurrency

                AppSelectionState.shared.setCurrency(
                    .tryCurrency
                )

           

                return
            }
        }

        rebuildCurrentCandlesticks()
        applyDefaultSMAsForCurrentPeriod()
        resetViewportForCurrentPeriod()

        chartView?.needsDisplay = true
    }

    @objc private func globalSymbolChanged(
        _ notification: Notification
    ) {

        let symbol =
            AppSelectionState.shared.selectedSymbol

        fetchStockData(
            symbol: symbol
        )
    }
 
    // MARK: - Fetch Stock Data

    private func fetchStockData(
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

        // -------------------------------------------------
        // Yeni istek kimliği
        //
        // Eski istek daha sonra dönse bile sonucu
        // artık kabul edilmeyecek.
        // -------------------------------------------------

        let fetchID = UUID()

        currentFetchID = fetchID

        // -------------------------------------------------
        // Loading göster
        //
        // Eski grafik silinmiyor.
        // -------------------------------------------------

        showLoadingOverlay(
            for: normalizedSymbol
        )

        let endDate = Date()

        let startDate =
            Calendar.current.date(
                byAdding: .day,
                value: -1000,
                to: endDate
            ) ?? endDate

        IsYatirimService.shared.fetchHisseVerileri(

            hisse: normalizedSymbol,

            startDate: startDate,

            endDate: endDate

        ) { [weak self] result in

            DispatchQueue.main.async {

                guard let self = self else {
                    return
                }

                // -------------------------------------------------
                // Bu cevap artık güncel değil.
                //
                // Örneğin:
                // SISE isteği devam ederken THYAO seçildiyse
                // ve SISE cevabı sonradan geldiyse SISE cevabı
                // tamamen yok sayılır.
                // -------------------------------------------------

                guard self.currentFetchID == fetchID else {
                    return
                }

                switch result {
                    
                case .success(let candlesticks):

                    self.hideLoadingOverlay()

                    if candlesticks.isEmpty {
                        self.onDataFetchCompleted?(
                            normalizedSymbol,
                            false
                        )
                        return
                    }

                    self.dailyCandlesticks = candlesticks

                    self.rebuildCurrentCandlesticks()
                    self.applyDefaultSMAsForCurrentPeriod()
                    self.resetViewportForCurrentPeriod()
                    self.chartView?.needsDisplay = true

                    self.onDataFetchCompleted?(
                        normalizedSymbol,
                        true
                    )
        
                case .failure(let error):

                    self.hideLoadingOverlay()

                    self.onDataFetchCompleted?(
                        normalizedSymbol,
                        false
                    )

                    print(
                        "Hisse verisi alınamadı: \(error)"
                    )
                }
            }
        }
    }

    // MARK: - Period

    @objc
    private func periodChanged(
        _ sender: NSSegmentedControl
    ) {

        switch sender.selectedSegment {

        case 0:
            chartPeriod = .daily

        case 1:
            chartPeriod = .weekly

        default:
            return
        }

        rebuildCurrentCandlesticks()

        applyDefaultSMAsForCurrentPeriod()

        resetViewportForCurrentPeriod()

        chartView?.needsDisplay = true
    }

    // MARK: - Rebuild Current Candlesticks

    private func rebuildCurrentCandlesticks() {

        guard !dailyCandlesticks.isEmpty else {

            currentCandlesticks = []

            chartView?.candlesticks = []

            return
        }

        let currencyCandlesticks =
            candlesticksForSelectedCurrency(
                from: dailyCandlesticks
            )

        guard !currencyCandlesticks.isEmpty else {

            currentCandlesticks = []

            chartView?.candlesticks = []

            return
        }

        switch chartPeriod {

        case .daily:

            currentCandlesticks =
                currencyCandlesticks

        case .weekly:

            currentCandlesticks =
                WeeklyCandlestickBuilder.build(
                    from: currencyCandlesticks
                )
        }

        chartView?.candlesticks =
            currentCandlesticks

        chartView?.needsDisplay = true
    }

    // MARK: - Currency Conversion

    private func candlesticksForSelectedCurrency(
        from candles: [Candlestick]
    ) -> [Candlestick] {

        switch chartCurrency {

        case .tryCurrency:

            return candles

        case .usd:

            return candles.compactMap { candle in

                guard
                    let usdMax = candle.usdMax,
                    let usdMin = candle.usdMin,
                    let usdAOF = candle.usdWeightedAverage
                else {
                    return nil
                }

                return Candlestick(
                    max: usdMax,
                    min: usdMin,
                    weightedAverage: usdAOF,
                    date: candle.date,
                    usdMax: usdMax,
                    usdMin: usdMin,
                    usdWeightedAverage: usdAOF
                )
            }
        }
    }

    // MARK: - Viewport

    private func resetViewportForCurrentPeriod() {

        guard let chartView = chartView else {
            return
        }

        switch chartPeriod {

        case .daily:

            chartView.setVisibleBarCount(
                dailyVisibleBarCount
            )

        case .weekly:

            chartView.setVisibleBarCount(
                weeklyVisibleBarCount
            )
        }

        chartView.resetVisibleRange()

        chartView.needsDisplay = true
    }



    // MARK: - Indicators

    @objc private func openIndicatorPopup() {

        let popupVC =
            IndicatorPopupViewController()

        popupVC.delegate =
            self

        presentAsSheet(
            popupVC
        )
    }

    private func applyDefaultSMAsForCurrentPeriod() {

        activeSMAs.removeAll()

        switch chartPeriod {

        case .daily:

            activeSMAs[8] = []
            activeSMAs[34] = []

        case .weekly:

            activeSMAs[52] = []
        }

        calculateAndDisplaySMAs()
    }

    private func calculateAndDisplaySMAs() {

        guard !currentCandlesticks.isEmpty else {
            return
        }

        let prices =
            IndicatorCalculator
                .getWeightedAveragePrices(
                    from: currentCandlesticks
                )

        for period in activeSMAs.keys {

            let smaValues =
                IndicatorCalculator.calculateSMA(
                    prices: prices,
                    period: period
                )

            activeSMAs[period] =
                smaValues
        }

        chartView?.activeSMAs =
            activeSMAs

        chartView?.candlesticks =
            currentCandlesticks

        chartView?.needsDisplay = true

        updateSMAButtons()
    }

    // MARK: - SMA Buttons

    private func updateSMAButtons() {

        guard let container =
                smaContainerView
        else {
            return
        }

        smaButtons.values.forEach {
            $0.removeFromSuperview()
        }

        smaButtons.removeAll()

        var xOffset: CGFloat = 0

        for period in activeSMAs.keys.sorted() {

            let button = NSButton()

            button.title =
                "SMA \(period)"

            button.bezelStyle =
                .rounded

            button.font =
                NSFont.systemFont(
                    ofSize: 11
                )

            button.target =
                self

            button.action =
                #selector(toggleSMA(_:))

            button.tag =
                period

            button.translatesAutoresizingMaskIntoConstraints =
                false

            container.addSubview(
                button
            )

            NSLayoutConstraint.activate([

                button.leadingAnchor.constraint(
                    equalTo:
                        container.leadingAnchor,
                    constant:
                        xOffset
                ),

                button.centerYAnchor.constraint(
                    equalTo:
                        container.centerYAnchor
                ),

                button.widthAnchor.constraint(
                    equalToConstant:
                        60
                )
            ])

            smaButtons[period] =
                button

            xOffset += 65
        }
    }

    @objc private func toggleSMA(
        _ sender: NSButton
    ) {

        let period =
            sender.tag

        if activeSMAs[period] != nil {

            activeSMAs.removeValue(
                forKey: period
            )

        } else {

            let prices =
                IndicatorCalculator
                    .getWeightedAveragePrices(
                        from: currentCandlesticks
                    )

            let smaValues =
                IndicatorCalculator.calculateSMA(
                    prices:
                        prices,
                    period:
                        period
                )

            activeSMAs[period] =
                smaValues
        }

        chartView?.activeSMAs =
            activeSMAs

        chartView?.candlesticks =
            currentCandlesticks

        chartView?.needsDisplay =
            true

        updateSMAButtons()
    }

    // MARK: - Deinit

    deinit {

        NotificationCenter.default.removeObserver(
            self
        )
    }
}

// MARK: - Refresh

extension ChartDetailViewController {

    func refreshChart() {

        chartView?.needsDisplay =
            true

        chartContainerView.needsLayout =
            true

        chartContainerView.layoutSubtreeIfNeeded()
    }
}

// MARK: - IndicatorPopupDelegate

extension ChartDetailViewController:
    IndicatorPopupDelegate {

    func didSelectIndicators(
        selectedSMAs: [Int]
    ) {

        guard !currentCandlesticks.isEmpty else {
            return
        }

        let prices =
            IndicatorCalculator
                .getWeightedAveragePrices(
                    from: currentCandlesticks
                )

        // Yeni seçilen SMA'ları mevcut
        // SMA'ların üzerine ekle.

        for period in selectedSMAs {

            let smaValues =
                IndicatorCalculator.calculateSMA(
                    prices:
                        prices,
                    period:
                        period
                )

            activeSMAs[period] =
                smaValues
        }

        chartView?.activeSMAs =
            activeSMAs

        chartView?.candlesticks =
            currentCandlesticks

        chartView?.needsDisplay =
            true

        updateSMAButtons()
    }
}
