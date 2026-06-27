// ChartDetailViewController.swift
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
    
   // var downloadManagerForPrices:DownloadManager?
    
    var stockData:[Value]?
    var dateAndPrices :[(date: Date, price: Double)] = []
    var dataString:String?
    
    
    private var activeSMAs: [Int: [Double?]] = [:]  // YENİ: Aktif SMA'lar
    private var smaButtons: [Int: NSButton] = [:]   // YENİ: SMA butonları
    
    private var smaContainerView: NSView?
    
    private var chartPeriod: ChartPeriod = .daily
    
    private var dailyCandlesticks: [Candlestick] = []
    
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
        
        //bu textfiel icinde sembol yazildiktan sonra enter basılınıca deleagte fnksiyonlarinin calismasi için bu gerekli.
        symbolTextField.delegate = self
        
        // View ayarları
        setupView()
        setupUI()
        setupChartView()
    }
    
    private func setupView() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        view.autoresizingMask = [.width, .height]
        
        // Auto layout'u etkinleştir
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        chartView?.needsDisplay = true
    }
    
    // MARK: - Setup
    /*
    private func setupUI() {
        symbolTextField.placeholderString = "Hisse Kodu (örn: AAPL)"
        symbolTextField.stringValue = "AAPL"
        //symbolTextField.translatesAutoresizingMaskIntoConstraints = false
        
        fetchButton.title = "Veri Getir"
        fetchButton.target = self
        fetchButton.action = #selector(fetchButtonClicked)
        //fetchButton.translatesAutoresizingMaskIntoConstraints = false
        
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.wantsLayer = true
        chartContainerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
       
        // Auto Layout constraints
        NSLayoutConstraint.activate([
            // TextField constraints
            symbolTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            symbolTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            symbolTextField.widthAnchor.constraint(equalToConstant: 200),
            
            // Button constraints
            fetchButton.leadingAnchor.constraint(equalTo: symbolTextField.trailingAnchor, constant: 8),
            fetchButton.centerYAnchor.constraint(equalTo: symbolTextField.centerYAnchor),
            fetchButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // Chart container constraints - TÜM ALANI KAPLAYACAK ŞEKİLDE
            chartContainerView.topAnchor.constraint(equalTo: symbolTextField.bottomAnchor, constant: 20),
            chartContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chartContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chartContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
    }
    */
    private func setupUI() {
        symbolTextField.placeholderString = "Hisse Kodu (örn: SISE)"
        symbolTextField.stringValue = "SISE"
        symbolTextField.translatesAutoresizingMaskIntoConstraints = false
        
        fetchButton.title = "Veri Getir"
        fetchButton.target = self
        fetchButton.action = #selector(fetchButtonClicked)
        fetchButton.translatesAutoresizingMaskIntoConstraints = false
        
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        
        // Indicator Button
        let indicatorButton = NSButton()
        indicatorButton.title = "Ortalama/Gösterge Ekle"
        indicatorButton.bezelStyle = .rounded
        indicatorButton.target = self
        indicatorButton.action = #selector(openIndicatorPopup)
        indicatorButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicatorButton)
        
        view.addSubview(periodControl)

        periodControl.target = self
        periodControl.action = #selector(periodChanged)
        
        

        // SMA'ların gösterileceği container view
        let smaContainerView = NSView()
        smaContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(smaContainerView)

        
        
        // Önce tüm mevcut kısıtlamaları kaldır (opsiyonel, storyboard'dakileri değil sadece kodla eklenenleri etkiler)
        NSLayoutConstraint.deactivate(view.constraints)
        
        NSLayoutConstraint.activate([
            // TextField: sol, üst, sabit genişlik
            symbolTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            symbolTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            symbolTextField.widthAnchor.constraint(equalToConstant: 150),
            
            // Button: TextField'ın sağına, dikeyde ortala
            fetchButton.leadingAnchor.constraint(equalTo: symbolTextField.trailingAnchor, constant: 8),
            fetchButton.centerYAnchor.constraint(equalTo: symbolTextField.centerYAnchor),
            
            // Chart Container: TextField'ın altından başla, tüm genişlik ve kalan yükseklik
            chartContainerView.topAnchor.constraint(equalTo: symbolTextField.bottomAnchor, constant: 20),
            chartContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chartContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chartContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            indicatorButton.leadingAnchor.constraint(equalTo: fetchButton.trailingAnchor, constant: 8),
                indicatorButton.centerYAnchor.constraint(equalTo: symbolTextField.centerYAnchor),
                
                // SMA Container
                smaContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
               smaContainerView.leadingAnchor.constraint(
                equalTo: periodControl.trailingAnchor,
                constant: 10
            ),
                smaContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                smaContainerView.heightAnchor.constraint(equalToConstant: 25),
            
            periodControl.leadingAnchor.constraint(
                equalTo: indicatorButton.trailingAnchor,
                constant: 8
            ),

            periodControl.centerYAnchor.constraint(
                equalTo: indicatorButton.centerYAnchor
            ),

            periodControl.widthAnchor.constraint(
                equalToConstant: 150
            )
            
        ])
        
        // Container'ı referans olarak sakla
        self.smaContainerView = smaContainerView
    }
    private func setupChartView() {
        chartView = CandlestickChartView()
        guard let chartView = chartView else { return }
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.wantsLayer = true
        chartView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        chartContainerView.addSubview(chartView)
       
        // Chart view constraints - container'ın tümünü kapla
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
        ])
        
    }
    
    // MARK: - Actions

    @objc private func fetchButtonClicked() {
        let symbol = symbolTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !symbol.isEmpty else {
            showAlert(message: "Lütfen bir hisse kodu girin (örn: SISE, SNGYO, THYAO)")
            return
        }
        
        // Tarih aralığını belirle (son 100 gün veya belirli bir aralık)
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1000, to: endDate) ?? endDate
        
        // API'den veri çek
        fetchButton.isEnabled = false
        fetchButton.title = "Yükleniyor..."
        
        IsYatirimService.shared.fetchHisseVerileri(hisse: symbol, startDate: startDate, endDate: endDate) { [weak self] result in
            DispatchQueue.main.async {
                self?.fetchButton.isEnabled = true
                self?.fetchButton.title = "Veri Getir"
                
                switch result {
                case .success(let candlesticks):
                    if candlesticks.isEmpty {
                        self?.showAlert(message: "\(symbol) için veri bulunamadı.\nLütfen tarih aralığını kontrol edin.")
                    } else {
                        //self?.currentCandlesticks = candlesticks
                        //self?.chartView?.candlesticks = candlesticks
                        
                        self?.dailyCandlesticks = candlesticks

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
                        
                        
                        //self?.view.window?.title = "\(symbol) - Teknik Analiz (\(candlesticks.count) Gün)"
                        self?.updateWindowTitle()
                    }
                    
                case .failure(let error):
                    self?.showAlert(message: "Veri çekilirken hata oluştu:\n\(error.localizedDescription)")
                    print("Hata: \(error)")
                }
            }
        }
        
        //calculateAndDisplaySMAs()
        
    }
   /*
    @objc private func fetchButtonClicked() {
        let symbol = symbolTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !symbol.isEmpty else {
            showAlert(message: "Hisse Kodu")
            return
        }
        
        let url = UrlMaker.buildUrlFor(stockSymbol: symbol)
        
        //VARSA ESKİS DATA LAR BOSALTİLİYOR. YOKSA TABLONUN SONUNA EKLIYOR..
        stockData?.removeAll()
        dateAndPrices.removeAll()
        
        downloadManagerForPrices = DownloadManager(yuarel: url)
        downloadManagerForPrices?.delegate = self
                
        self.downloadManagerForPrices?.startDownload()
        
        /*
        // Fake veri üret
        currentCandlesticks = FakeDataGenerator.generateCandlesticks(count: 100, startPrice: 100.0)
        chartView?.candlesticks = currentCandlesticks
        */
        // Başlık güncelleme
        view.window?.title = "\(symbol) - Teknik Analiz"
    }
    */
    
    @objc
    private func periodChanged(
        _ sender: NSSegmentedControl
    ) {

        switch sender.selectedSegment {

        case 0:
            chartPeriod = .daily
            currentCandlesticks = dailyCandlesticks

        case 1:
            chartPeriod = .weekly
            currentCandlesticks =
                WeeklyCandlestickBuilder.build(
                    from: dailyCandlesticks
                )

        default:
            break
        }

        //calculateAndDisplaySMAs()
        applyDefaultSMAsForCurrentPeriod()
        chartView?.candlesticks = currentCandlesticks
        chartView?.needsDisplay = true

        updateWindowTitle()
    }
    private func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Uyarı"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Tamam")
        alert.runModal()
    }
    private func updateWindowTitle() {

        let symbol = symbolTextField.stringValue.uppercased()

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
        let popupVC = IndicatorPopupViewController()
        popupVC.delegate = self
        presentAsSheet(popupVC)
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
        guard !currentCandlesticks.isEmpty else { return }
        
        let prices = IndicatorCalculator.getWeightedAveragePrices(from: currentCandlesticks)
        
        for (period, _) in activeSMAs {
            let smaValues = IndicatorCalculator.calculateSMA(prices: prices, period: period)
            activeSMAs[period] = smaValues
        }
        
        // Grafiği yeniden çiz
        chartView?.activeSMAs = activeSMAs
        chartView?.candlesticks = currentCandlesticks
        
        // SMA butonlarını göster
        updateSMAButtons()
    }

    private func updateSMAButtons() {
        guard let container = smaContainerView else { return }
        
        // Eski butonları temizle
        smaButtons.values.forEach { $0.removeFromSuperview() }
        smaButtons.removeAll()
        
        var xOffset: CGFloat = 0
        
        for period in activeSMAs.keys.sorted() {
            let button = NSButton()
            button.title = "SMA \(period)"
            button.bezelStyle = .rounded
            button.font = NSFont.systemFont(ofSize: 11)
            button.target = self
            button.action = #selector(toggleSMA(_:))
            button.tag = period
            button.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: xOffset),
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 60)
            ])
            
            smaButtons[period] = button
            xOffset += 65
        }
    }

    @objc private func toggleSMA(_ sender: NSButton) {
        let period = sender.tag
        
        if let _ = activeSMAs[period] {
            // SMA'yı kaldır
            activeSMAs.removeValue(forKey: period)
        } else {
            // SMA'yı ekle
            let prices = IndicatorCalculator.getWeightedAveragePrices(from: currentCandlesticks)
            let smaValues = IndicatorCalculator.calculateSMA(prices: prices, period: period)
            activeSMAs[period] = smaValues
        }
        
        // Grafiği yeniden çiz
        chartView?.activeSMAs = activeSMAs
        chartView?.candlesticks = currentCandlesticks
        chartView?.needsDisplay = true
        
        // Butonları güncelle
        updateSMAButtons()
    }
    
}

// MARK: - SidebarSelectionDelegate
extension ChartDetailViewController: SidebarSelectionDelegate {
    func didSelectSidebarItem(_ item: SidebarItem) {
        if item.children == nil {
            symbolTextField.stringValue = item.name
            fetchButtonClicked()
        }
    }
}
extension ChartDetailViewController {
    func refreshChart() {
        // Grafiği yeniden çiz
        chartView?.needsDisplay = true
        
        // Container view'ı güncelle
        chartContainerView.needsLayout = true
        chartContainerView.layoutSubtreeIfNeeded()
    }
}

/*
extension ChartDetailViewController: DownloadManagerDelegate{
    
    
    func didFinishDownloadTaskWith(data: Data) {
        
        print("------------------------download has been complete -------------------------")
        
    }
    
}
*/
// MARK: - IndicatorPopupDelegate
extension ChartDetailViewController: IndicatorPopupDelegate {
    func didSelectIndicators(selectedSMAs: [Int]) {
        // Önceki SMA'ları temizle
        activeSMAs.removeAll()
        
        let prices = IndicatorCalculator.getWeightedAveragePrices(from: currentCandlesticks)
        
        for period in selectedSMAs {
            let smaValues = IndicatorCalculator.calculateSMA(prices: prices, period: period)
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

extension ChartDetailViewController: NSTextFieldDelegate {
    //hisse sembol girildikten sonra enter basilinca bu kod cagrilicak. simdilik bir textfield var ama ilerde sorun olursa hangi textfield içinde ne yapılacaksa ona gore duzenlenmeli bu delegate
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Enter key was pressed
                
                self.fetchButtonClicked()
                return true
            }
            return false
        }
    
    
}
