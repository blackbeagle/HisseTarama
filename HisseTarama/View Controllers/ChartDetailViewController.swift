import Cocoa

enum ChartPeriod {
    case daily
    case weekly
}

class ChartDetailViewController: NSViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var symbolTextField: NSTextField!
    @IBOutlet weak var fetchButton: NSButton!
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
    
    private var dailyCandlesticks: [Candlestick] = []
    
    // Günlük ve haftalık görünüm
    private let dailyVisibleBarCount = 150
    private let weeklyVisibleBarCount = 80
    
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        symbolTextField.delegate = self
        
        setupView()
        setupUI()
        setupChartView()
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
    
    // MARK: - Setup
    
    private func setupUI() {
        
        symbolTextField.placeholderString =
            "Hisse Kodu (örn: SISE)"
        
        symbolTextField.stringValue = "SISE"
        symbolTextField.translatesAutoresizingMaskIntoConstraints = false
        
        fetchButton.title = "Veri Getir"
        fetchButton.target = self
        fetchButton.action = #selector(fetchButtonClicked)
        fetchButton.translatesAutoresizingMaskIntoConstraints = false
        
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Indicator Button
        
        let indicatorButton = NSButton()
        
        indicatorButton.title =
            "Ortalama/Gösterge Ekle"
        
        indicatorButton.bezelStyle = .rounded
        indicatorButton.target = self
        indicatorButton.action = #selector(openIndicatorPopup)
        indicatorButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(indicatorButton)
        
        // Period Control
        
        view.addSubview(periodControl)
        
        periodControl.target = self
        periodControl.action = #selector(periodChanged)
        
        // SMA Container
        
        let smaContainerView = NSView()
        
        smaContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(smaContainerView)
        
        NSLayoutConstraint.deactivate(
            view.constraints
        )
        
        NSLayoutConstraint.activate([
            
            symbolTextField.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 40
            ),
            
            symbolTextField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            
            symbolTextField.widthAnchor.constraint(
                equalToConstant: 150
            ),
            
            fetchButton.leadingAnchor.constraint(
                equalTo: symbolTextField.trailingAnchor,
                constant: 8
            ),
            
            fetchButton.centerYAnchor.constraint(
                equalTo: symbolTextField.centerYAnchor
            ),
            
            chartContainerView.topAnchor.constraint(
                equalTo: symbolTextField.bottomAnchor,
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
            ),
            
            indicatorButton.leadingAnchor.constraint(
                equalTo: fetchButton.trailingAnchor,
                constant: 8
            ),
            
            indicatorButton.centerYAnchor.constraint(
                equalTo: symbolTextField.centerYAnchor
            ),
            
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
            
            smaContainerView.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 40
            ),
            
            smaContainerView.leadingAnchor.constraint(
                equalTo: periodControl.trailingAnchor,
                constant: 10
            ),
            
            smaContainerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: 0
            ),
            
            smaContainerView.heightAnchor.constraint(
                equalToConstant: 25
            )
        ])
        
        self.smaContainerView =
            smaContainerView
    }
    
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
    
    // MARK: - Actions
    
    @objc private func fetchButtonClicked() {
        
        let symbol =
            symbolTextField.stringValue
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()
        
        guard !symbol.isEmpty else {
            
            showAlert(
                message:
                    "Lütfen bir hisse kodu girin (örn: SISE, SNGYO, THYAO)"
            )
            
            return
        }
        
        let endDate = Date()
        
        let startDate =
            Calendar.current.date(
                byAdding: .day,
                value: -1000,
                to: endDate
            ) ?? endDate
        
        fetchButton.isEnabled = false
        fetchButton.title = "Yükleniyor..."
        
        IsYatirimService.shared.fetchHisseVerileri(
            hisse: symbol,
            startDate: startDate,
            endDate: endDate
        ) { [weak self] result in
            
            DispatchQueue.main.async {
                
                self?.fetchButton.isEnabled = true
                self?.fetchButton.title = "Veri Getir"
                
                switch result {
                    
                case .success(let candlesticks):
                    
                    if candlesticks.isEmpty {
                        
                        self?.showAlert(
                            message:
                                "\(symbol) için veri bulunamadı.\nLütfen tarih aralığını kontrol edin."
                        )
                        
                    } else {
                        
                        self?.dailyCandlesticks =
                            candlesticks
                        
                        if self?.chartPeriod == .weekly {
                            
                            self?.currentCandlesticks =
                                WeeklyCandlestickBuilder.build(
                                    from: candlesticks
                                )
                            
                        } else {
                            
                            self?.currentCandlesticks =
                                candlesticks
                        }
                        
                        self?.chartView?.candlesticks =
                            self?.currentCandlesticks ?? []
                        
                        self?.applyDefaultSMAsForCurrentPeriod()
                        
                        self?.resetViewportForCurrentPeriod()
                        
                        self?.updateWindowTitle()
                    }
                    
                case .failure(let error):
                    
                    self?.showAlert(
                        message:
                            "Veri çekilirken hata oluştu:\n\(error.localizedDescription)"
                    )
                    
                    print(
                        "Hata: \(error)"
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
            
            currentCandlesticks =
                dailyCandlesticks
            
        case 1:
            
            chartPeriod = .weekly
            
            currentCandlesticks =
                WeeklyCandlestickBuilder.build(
                    from: dailyCandlesticks
                )
            
        default:
            
            return
        }
        
        chartView?.candlesticks =
            currentCandlesticks
        
        applyDefaultSMAsForCurrentPeriod()
        
        resetViewportForCurrentPeriod()
        
        chartView?.needsDisplay = true
        
        updateWindowTitle()
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
    
    // MARK: - Alert
    
    private func showAlert(message: String) {
        
        let alert = NSAlert()
        
        alert.messageText = "Uyarı"
        alert.informativeText = message
        alert.alertStyle = .warning
        
        alert.addButton(
            withTitle: "Tamam"
        )
        
        alert.runModal()
    }
    
    private func updateWindowTitle() {
        
        let symbol =
            symbolTextField.stringValue.uppercased()
        
        let periodText: String
        
        switch chartPeriod {
            
        case .daily:
            periodText = "Günlük"
            
        case .weekly:
            periodText = "Haftalık"
        }
        
        view.window?.title =
            "\(symbol) - \(periodText) (\(currentCandlesticks.count) Bar)"
    }
    
    // MARK: - Indicators
    
    @objc private func openIndicatorPopup() {
        
        let popupVC =
            IndicatorPopupViewController()
        
        popupVC.delegate = self
        
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
    
    private func updateSMAButtons() {
        
        guard let container = smaContainerView else {
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
            
            button.bezelStyle = .rounded
            
            button.font =
                NSFont.systemFont(
                    ofSize: 11
                )
            
            button.target = self
            button.action = #selector(toggleSMA(_:))
            button.tag = period
            button.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(button)
            
            NSLayoutConstraint.activate([
                
                button.leadingAnchor.constraint(
                    equalTo: container.leadingAnchor,
                    constant: xOffset
                ),
                
                button.centerYAnchor.constraint(
                    equalTo: container.centerYAnchor
                ),
                
                button.widthAnchor.constraint(
                    equalToConstant: 60
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
        
        let period = sender.tag
        
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
}

// MARK: - SidebarSelectionDelegate

extension ChartDetailViewController: SidebarSelectionDelegate {
    
    func didSelectSidebarItem(
        _ item: SidebarItem
    ) {
        
        if item.children == nil {
            
            symbolTextField.stringValue =
                item.name
            
            fetchButtonClicked()
        }
    }
}

// MARK: - Refresh

extension ChartDetailViewController {
    
    func refreshChart() {
        
        chartView?.needsDisplay = true
        
        chartContainerView.needsLayout = true
        
        chartContainerView.layoutSubtreeIfNeeded()
    }
}

// MARK: - IndicatorPopupDelegate

extension ChartDetailViewController: IndicatorPopupDelegate {
    
    func didSelectIndicators(selectedSMAs: [Int]) {

        guard !currentCandlesticks.isEmpty else {
            return
        }

        let prices =
            IndicatorCalculator
                .getWeightedAveragePrices(
                    from: currentCandlesticks
                )

        // Yeni seçilen SMA'ları mevcut SMA'ların
        // üzerine ekle.
        //
        // activeSMAs bir Dictionary olduğu için
        // aynı period zaten varsa tekrar oluşturulmaz;
        // sadece değeri güncellenir.
        for period in selectedSMAs {

            let smaValues =
                IndicatorCalculator.calculateSMA(
                    prices: prices,
                    period: period
                )

            activeSMAs[period] = smaValues
        }

        // Grafiği yeniden çiz
        chartView?.activeSMAs = activeSMAs
        chartView?.candlesticks = currentCandlesticks
        chartView?.needsDisplay = true

        // SMA butonlarını güncelle
        updateSMAButtons()
    }
}

// MARK: - NSTextFieldDelegate

extension ChartDetailViewController: NSTextFieldDelegate {
    
    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        
        if commandSelector ==
            #selector(
                NSResponder.insertNewline(_:)
            ) {
            
            self.fetchButtonClicked()
            
            return true
        }
        
        return false
    }
}
