// MainSplitViewController.swift

import Cocoa
class MainSplitViewController: NSSplitViewController, SidebarSelectionDelegate{

    // MARK: - Properties

    private var sidebarWasCollapsed = false

    // MARK: - View Lifecycle

    override func viewDidLoad() {

        super.viewDidLoad()

        // Split view ayarları
        setupSplitView()

        view.window?.toolbar?.isVisible = true

        // View'in tüm alanı kaplamasını sağla
        view.autoresizingMask = [.width, .height]
        view.wantsLayer = true

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

        // Grafikleri yenile
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

    @objc private func windowDidResize(
        _ notification: Notification
    ) {

        // Sidebar kapalıysa genişlik hesaplama
        if let sidebarItem = splitViewItems.first,
           !sidebarItem.isCollapsed {

            adjustSidebarWidth()
        }

        // Grafikleri yeniden çiz
        if let detailVC =
            children.last as? ChartDetailViewController {

            detailVC.refreshChart()
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

            // Grafikleri yenile
            if let detailVC =
                self.children.last as? ChartDetailViewController {

                detailVC.refreshChart()
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

            // Grafikleri yenile
            if let detailVC =
                self.children.last as? ChartDetailViewController {

                detailVC.refreshChart()
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

        print(
            "Seçilen hisse: \(stock.symbol)"
        )

        print(
            "AppState seçili hisse: " +
            "\(AppStockState.shared.selectedStock?.symbol ?? "-")"
        )

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

    // MARK: - Deinit

    deinit {

        NotificationCenter.default.removeObserver(self)
    }
}
