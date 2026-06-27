// MainSplitViewController.swift
import Cocoa

class MainSplitViewController: NSSplitViewController {
    

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
    
    private func setupSplitView() {
        
        // Split view'in tüm alanı kaplamasını sağla
        splitView.autoresizingMask = [.width, .height]
        splitView.dividerStyle = .paneSplitter
    
        // Sidebar item'ı ayarla
        if let sidebarItem = splitViewItems.first {
            sidebarItem.minimumThickness = 150
            sidebarItem.maximumThickness = 400
            sidebarItem.canCollapse = true
        }
        
        // İkinci item'ın tüm alanı kaplamasını sağla
        if let detailItem = splitViewItems.last {
            detailItem.minimumThickness = 400
            detailItem.canCollapse = false
        }
    }

    func adjustSidebarWidthManually() {
            adjustSidebarWidth()
            // Grafikleri yenile
            if let detailVC = children.last as? ChartDetailViewController {
                detailVC.refreshChart()
            }
        }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
  
            if let window = view.window {
                print("Toolbar visible: \(window.toolbar?.isVisible ?? false)")
                print("Toolbar items: \(window.toolbar?.items ?? [])")
            }
        
        // Pencere açıldığında sidebar genişliğini ayarla
        DispatchQueue.main.async { [weak self] in
            self?.adjustSidebarWidth()
            
            
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        adjustSidebarWidth()
    }
    
    private func adjustSidebarWidth() {
        
        guard let sidebarItem = splitViewItems.first,
              let window = view.window else { return }
        
        let windowWidth = window.frame.width
        let sidebarWidth = max(150, min(400, windowWidth / 5))
        
        if sidebarItem.minimumThickness != sidebarWidth {
            
            sidebarItem.minimumThickness = sidebarWidth
            splitView.setPosition(sidebarWidth, ofDividerAt: 0)
        }
    }
    
  
     

  
    
    // MARK: - Window Notifications
    @objc private func windowDidResize(_ notification: Notification) {
        // Pencere yeniden boyutlandırıldığında sidebar genişliğini güncelle
        adjustSidebarWidth()
        
        // Grafikleri yeniden çiz
        if let detailVC = children.last as? ChartDetailViewController {
            detailVC.refreshChart()
        }
    }
    
    @objc private func windowDidEnterFullScreen(_ notification: Notification) {
        // Full screen'e girildiğinde
        DispatchQueue.main.async { [weak self] in
            self?.adjustSidebarWidth()
            self?.view.layoutSubtreeIfNeeded()
            
            // Grafikleri yenile
            if let detailVC = self?.children.last as? ChartDetailViewController {
                detailVC.refreshChart()
            }
        }
    }
    
    @objc private func windowDidExitFullScreen(_ notification: Notification) {
        // Full screen'den çıkıldığında
        DispatchQueue.main.async { [weak self] in
            self?.adjustSidebarWidth()
            self?.view.layoutSubtreeIfNeeded()
            
            // Grafikleri yenile
            if let detailVC = self?.children.last as? ChartDetailViewController {
                detailVC.refreshChart()
            }
        }
    }
    
    deinit {
        // Notification observer'ları temizle
        NotificationCenter.default.removeObserver(self)
    }
}

