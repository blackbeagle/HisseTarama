import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
       
        createMainWindow()
        
    }
    
    
    private func createMainWindow() {
        // Split view controller'ı oluştur
        let splitViewController = MainSplitViewController()
        
        // Pencereyi oluştur
        let window = NSWindow(contentViewController: splitViewController)
        
        // Pencere ayarları
        window.title = "Teknik Analiz ve Tarama Programı"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 800, height: 600)
        window.collectionBehavior = [.fullScreenPrimary, .fullScreenAuxiliary]
        
        // Content view'in tüm pencereyi kaplamasını sağla
        window.contentView?.autoresizingMask = [.width, .height]
        
        // Pencereyi maksimize et (zoom yap)
        if let screen = window.screen ?? NSScreen.main {
            // Önce pencereyi göster
            window.makeKeyAndOrderFront(nil)
            
            // Sonra zoom (maksimize) yap
            DispatchQueue.main.async {
                window.zoom(nil)  // Bu zoom butonuna basılmış gibi davranır
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
        
        self.window = window
        
        // Sidebar genişliğini ayarla
        DispatchQueue.main.async {
            splitViewController.adjustSidebarWidthManually()
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
           guard let screenFrame = NSScreen.main?.visibleFrame else { return }
        window.setFrame(screenFrame, display: true, animate: true)
       }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

