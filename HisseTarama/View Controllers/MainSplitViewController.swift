// MainSplitViewController.swift

import Cocoa

class MainSplitViewController: NSSplitViewController,
                               SidebarSelectionDelegate {

    // MARK: - Properties

    private var sidebarWasCollapsed = false
    
    
    // MARK: - Data Fetch Coordination

    private var fetchStatusSymbol: String?

    private var technicalFetchFinished = false
    private var fundamentalFetchFinished = false

    private var technicalFetchSuccess = false
    private var fundamentalFetchSuccess = false
    


    // MARK: - View Lifecycle

    override func viewDidLoad() {

        super.viewDidLoad()

        // Split view ayarları
        setupSplitView()

        view.window?.toolbar?.isVisible = true

        // View'in tüm alanı kaplamasını sağla
        view.autoresizingMask = [.width, .height]
        view.wantsLayer = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(globalSymbolChanged(_:)),
            name: AppSelectionState.symbolDidChange,
            object: nil
        )
        
        // Pencere boyut değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: view.window
        )

        // Full screen değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidEnterFullScreen),
            name: NSWindow.didEnterFullScreenNotification,
            object: view.window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidExitFullScreen),
            name: NSWindow.didExitFullScreenNotification,
            object: view.window
        )
    }

    // MARK: - Split View Setup

    private func setupSplitView() {

        splitView.autoresizingMask = [.width, .height]
        splitView.dividerStyle = .paneSplitter

        // Sidebar
        if let sidebarItem = splitViewItems.first {

            sidebarItem.minimumThickness = 150
            sidebarItem.maximumThickness = 400
            sidebarItem.canCollapse = true
        }

        // Detail
        if let detailItem = splitViewItems.last {

            detailItem.minimumThickness = 400
            detailItem.canCollapse = false
        }
    }

    // MARK: - Sidebar

    func toggleSidebar() {

        guard let sidebarItem = splitViewItems.first else {
            return
        }

        if sidebarItem.isCollapsed {

            // Sidebar'ı göster
            sidebarItem.isCollapsed = false
            sidebarWasCollapsed = false

            DispatchQueue.main.async { [weak self] in

                guard let self = self else {
                    return
                }

                self.adjustSidebarWidth()
                self.view.layoutSubtreeIfNeeded()
            }

        } else {

            // Sidebar'ı gizle
            sidebarWasCollapsed = true
            sidebarItem.isCollapsed = true

            view.layoutSubtreeIfNeeded()
        }
    }

    // MARK: - Sidebar Width

    func adjustSidebarWidthManually() {

        guard let sidebarItem = splitViewItems.first,
              !sidebarItem.isCollapsed else {
            return
        }

        adjustSidebarWidth()

        // Grafik alanını yenile
        if let detailTabVC =
            children.last as? DetailTabViewController {

            detailTabVC.refreshChart()
        }
    }

    private func adjustSidebarWidth() {

        guard let sidebarItem = splitViewItems.first,
              let window = view.window,
              !sidebarItem.isCollapsed else {
            return
        }

        let windowWidth = window.frame.width

        let sidebarWidth =
            max(
                150,
                min(
                    400,
                    windowWidth / 5
                )
            )

        if sidebarItem.minimumThickness != sidebarWidth {

            sidebarItem.minimumThickness = sidebarWidth

            splitView.setPosition(
                sidebarWidth,
                ofDividerAt: 0
            )
        }
    }

    // MARK: - View Appearance

    override func viewDidAppear() {

        super.viewDidAppear()
        
        //print("ANA PENCERE BAŞLIĞI: \(view.window?.title ?? "nil")")

        if let window = view.window {

            print(
                "Toolbar visible: \(window.toolbar?.isVisible ?? false)"
            )

            print(
                "Toolbar items: \(window.toolbar?.items ?? [])"
            )
        }

        // Sidebar seçim delegate bağlantısı
        if let sidebarVC =
            splitViewItems.first?.viewController
                as? SidebarViewController {

            sidebarVC.selectionDelegate = self
        }

        // Pencere açıldığında sidebar genişliğini ayarla
        DispatchQueue.main.async { [weak self] in

            self?.adjustSidebarWidth()
        }
        
        // GEÇİCİ TEST
           // FinancialDataService.shared.testFetch()
    }

    override func viewDidLayout() {

        super.viewDidLayout()

        guard let sidebarItem = splitViewItems.first else {
            return
        }

        // Sidebar kapalıyken genişlik ayarı yapma.
        if !sidebarItem.isCollapsed {

            adjustSidebarWidth()
        }
    }

    // MARK: - Window Notifications
    
    @objc private func globalSymbolChanged(
        _ notification: Notification
    ) {
        let symbol = AppSelectionState.shared.selectedSymbol

        guard !symbol.isEmpty else {
            return
        }

        view.window?.title = "\(symbol) - Teknik & Temel Analiz"

       // print("ANA PENCERE BAŞLIĞI GÜNCELLENDİ: \(symbol)")
    }

    @objc private func windowDidResize(
        _ notification: Notification
    ) {

        // Sidebar kapalıysa genişlik hesaplama
        if let sidebarItem = splitViewItems.first,
           !sidebarItem.isCollapsed {

            adjustSidebarWidth()
        }

        // Detail tab içerisindeki teknik grafiği yenile
        if let detailTabVC =
            children.last as? DetailTabViewController {

            detailTabVC.refreshChart()
        }
    }

    @objc private func windowDidEnterFullScreen(
        _ notification: Notification
    ) {

        DispatchQueue.main.async { [weak self] in

            guard let self = self else {
                return
            }

            if let sidebarItem = self.splitViewItems.first,
               !sidebarItem.isCollapsed {

                self.adjustSidebarWidth()
            }

            self.view.layoutSubtreeIfNeeded()

            // Detail tab içerisindeki teknik grafiği yenile
            if let detailTabVC =
                self.children.last as? DetailTabViewController {

                detailTabVC.refreshChart()
            }
        }
    }

    @objc private func windowDidExitFullScreen(
        _ notification: Notification
    ) {

        DispatchQueue.main.async { [weak self] in

            guard let self = self else {
                return
            }

            if let sidebarItem = self.splitViewItems.first,
               !sidebarItem.isCollapsed {

                self.adjustSidebarWidth()
            }

            self.view.layoutSubtreeIfNeeded()

            // Detail tab içerisindeki teknik grafiği yenile
            if let detailTabVC =
                self.children.last as? DetailTabViewController {

                detailTabVC.refreshChart()
            }
        }
    }

    // MARK: - Sidebar Selection

    func sidebar(
        _ sidebar: SidebarViewController,
        didSelect selection: SidebarSelection
    ) {

        switch selection {

        case .stock(let symbol):

            let stock = Stock(
                symbol: symbol
            )

            AppStockState.shared.selectStock(
                stock
            )

            showSelectedStock(
                stock
            )
        }
    }
    
    private func showSelectedStock(
        _ stock: Stock
    ) {

        // Yeni hisse için teknik + temel veri
        // sonuç takibini başlat.
        beginFetchTracking(
            for: stock.symbol
        )

        print(
            "Seçilen hisse: \(stock.symbol)"
        )

        print(
            "AppState seçili hisse: " +
            "\(AppStockState.shared.selectedStock?.symbol ?? "-")"
        )

        // Ana pencere başlığını güncelle
        view.window?.title =
            "\(stock.symbol) - Teknik & Temel Analiz"

        guard let detailTabVC =
            children.last as? DetailTabViewController
        else {

            print(
                "HATA: DetailTabViewController bulunamadı."
            )

            return
        }

        detailTabVC.selectStock(
            symbol: stock.symbol
        )
    }
    

    
    
    // MARK: - Data Fetch Coordination

    private func beginFetchTracking(
        for symbol: String
    ) {

        print(">>> BEGIN TRACKING SELF: \(ObjectIdentifier(self)) <<<")
        print(">>> BEGIN TRACKING SYMBOL: \(symbol) <<<")

        let normalizedSymbol =
            symbol
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        fetchStatusSymbol = normalizedSymbol
        technicalFetchFinished = false
        fundamentalFetchFinished = false
        technicalFetchSuccess = false
        fundamentalFetchSuccess = false

        print(
            "VERİ TAKİBİ BAŞLADI: \(normalizedSymbol)"
        )

        print(
            ">>> BEGIN TRACKING STORED SYMBOL: \(fetchStatusSymbol ?? "nil") <<<"
        )
        print(">>> BEGIN TRACKING SELF END: \(ObjectIdentifier(self)) <<<")
    }

    // MARK: - Technical Data Result
    // MARK: - Technical Data Result

    func technicalDataDidFinish(
        symbol: String,
        success: Bool
    ) {

        print(
            "MAIN SPLIT: technicalDataDidFinish GELDİ - \(symbol) - \(success)"
        )

        DispatchQueue.main.async { [weak self] in

            guard let self = self else {
                return
            }

            print(
                ">>> TECHNICAL MAIN QUEUE BLOĞUNA GİRİLDİ <<<"
            )

            let normalizedSymbol =
                symbol
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .uppercased()

            print(
                ">>> TECHNICAL CALLBACK SELF: \(ObjectIdentifier(self)) <<<"
            )

            print(
                ">>> TECHNICAL SELF GEÇTİ <<<"
            )

            // Tracking daha önce başlatılmadıysa
            // callback üzerinden başlat.
            if self.fetchStatusSymbol == nil {

                self.fetchStatusSymbol = normalizedSymbol

                self.technicalFetchFinished = false
                self.fundamentalFetchFinished = false
                self.technicalFetchSuccess = false
                self.fundamentalFetchSuccess = false

                print(
                    ">>> TECHNICAL TRACKING CALLBACK ÜZERİNDEN BAŞLATILDI: \(normalizedSymbol) <<<"
                )
            }

            guard
                let currentSymbol = self.fetchStatusSymbol,
                normalizedSymbol == currentSymbol
            else {

                print(
                    ">>> TECHNICAL SYMBOL EŞLEŞMEDİ: " +
                    "\(normalizedSymbol) / " +
                    "\(self.fetchStatusSymbol ?? "nil") <<<"
                )

                return
            }

            self.technicalFetchFinished = true
            self.technicalFetchSuccess = success

            print(
                "TRACKING DURUMU - TEKNİK: " +
                "technical=\(self.technicalFetchFinished), " +
                "fundamental=\(self.fundamentalFetchFinished), " +
                "symbol=\(self.fetchStatusSymbol ?? "-")"
            )

            self.evaluateFetchResult()
        }
    }

 
    // MARK: - Fundamental Data Result

    func fundamentalDataDidFinish(
        symbol: String,
        success: Bool
    ) {

        print(
            "MAIN SPLIT: fundamentalDataDidFinish GELDİ - \(symbol) - \(success)"
        )

        DispatchQueue.main.async { [weak self] in

            guard let self = self else {
                return
            }

            print(
                ">>> FUNDAMENTAL MAIN QUEUE BLOĞUNA GİRİLDİ <<<"
            )

            let normalizedSymbol =
                symbol
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .uppercased()

            print(
                ">>> FUNDAMENTAL CALLBACK SELF: \(ObjectIdentifier(self)) <<<"
            )

            // Tracking daha önce başlatılmadıysa
            // callback üzerinden başlat.
            if self.fetchStatusSymbol == nil {

                self.fetchStatusSymbol = normalizedSymbol

                self.technicalFetchFinished = false
                self.fundamentalFetchFinished = false
                self.technicalFetchSuccess = false
                self.fundamentalFetchSuccess = false

                print(
                    ">>> FUNDAMENTAL TRACKING CALLBACK ÜZERİNDEN BAŞLATILDI: \(normalizedSymbol) <<<"
                )
            }

            guard
                let currentSymbol = self.fetchStatusSymbol,
                normalizedSymbol == currentSymbol
            else {

                print(
                    ">>> FUNDAMENTAL SYMBOL EŞLEŞMEDİ: " +
                    "\(normalizedSymbol) / " +
                    "\(self.fetchStatusSymbol ?? "nil") <<<"
                )

                return
            }

            self.fundamentalFetchFinished = true
            self.fundamentalFetchSuccess = success

            print(
                "TRACKING DURUMU - TEMEL: " +
                "technical=\(self.technicalFetchFinished), " +
                "fundamental=\(self.fundamentalFetchFinished), " +
                "symbol=\(self.fetchStatusSymbol ?? "-")"
            )

            self.evaluateFetchResult()
        }
    }

    // MARK: - Evaluate Fetch Result

    private func evaluateFetchResult() {

        // İki veri kaynağından da cevap gelmeden
        // alert gösterme.
        guard
            technicalFetchFinished,
            fundamentalFetchFinished
        else {
            print(
                "VERİ TAKİBİ: İki sonuç da henüz gelmedi."
            )
            return
        }

        guard
            let symbol = fetchStatusSymbol
        else {
            return
        }

        print(
            "================================"
        )

        print(
            "TEKNİK + TEMEL VERİ TAKİBİ TAMAMLANDI"
        )

        print(
            "Hisse: \(symbol)"
        )

        print(
            "Teknik başarılı: \(technicalFetchSuccess)"
        )

        print(
            "Temel başarılı: \(fundamentalFetchSuccess)"
        )

        print(
            "================================"
        )

        var messages: [String] = []

        if !technicalFetchSuccess {
            messages.append(
                "Hisse fiyat bilgileri alınamadı."
            )
        }

        if !fundamentalFetchSuccess {
            messages.append(
                "Hisse Bilanço verisi alınamadı."
            )
        }

        // İki veri de başarılıysa alert gösterme.
        guard !messages.isEmpty else {
            print(
                "Her iki veri de başarıyla alındı."
            )
            return
        }

        showCombinedDataErrorAlert(
            symbol: symbol,
            messages: messages
        )
    }

    // MARK: - Combined Data Error Alert

    private func showCombinedDataErrorAlert(
        symbol: String,
        messages: [String]
    ) {
        
        print("!!! NSALERT ÇAĞRILIYOR: \(symbol) !!!")

        let alert = NSAlert()

        alert.messageText =
            "\(symbol) verileri alınamadı"

        alert.informativeText =
            messages.joined(
                separator: "\n"
            )

        alert.alertStyle = .warning

        alert.addButton(
            withTitle: "Tamam"
        )

        alert.runModal()
    }
    


    // MARK: - Deinit

    deinit {

        NotificationCenter.default.removeObserver(self)
    }
}
