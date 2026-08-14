import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // Storyboard tarafından oluşturulan ana pencere
    @IBOutlet weak var window: NSWindow!

    // MARK: - Application Launch

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        guard let window = window else {
            print("⚠️ Ana pencere storyboard'dan alınamadı.")
            return
        }

        self.window = window

        // -------------------------------------------------
        // Window Settings
        // -------------------------------------------------

        window.title =
            "Teknik Analiz ve Tarama Programı"

        window.styleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
            .fullSizeContentView
        ]

        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true

        window.minSize =
            NSSize(
                width: 800,
                height: 600
            )

        window.contentView?.autoresizingMask = [
            .width,
            .height
        ]

        // -------------------------------------------------
        // Restoration
        // -------------------------------------------------

        window.isRestorable = false
        window.restorationClass = nil

        // -------------------------------------------------
        // Delegate
        // -------------------------------------------------

        window.delegate = self

        // -------------------------------------------------
        // Başlangıç boyutu
        // -------------------------------------------------

        DispatchQueue.main.async { [weak self] in

            guard
                let self = self,
                let window = self.window,
                let screen =
                    window.screen ?? NSScreen.main
            else {
                return
            }

            let visibleFrame =
                screen.visibleFrame

            window.setFrame(
                visibleFrame,
                display: true,
                animate: false
            )

            window.makeKeyAndOrderFront(nil)

            // MainSplitViewController storyboard'dan
            // oluşturulduğu için burada onu buluyoruz.
            if let splitViewController =
                window.contentViewController
                as? MainSplitViewController {

                splitViewController
                    .adjustSidebarWidthManually()
            }
        }
    }

    // MARK: - Standard Window Frame
    //
    // macOS title bar'a çift tıklandığında
    // kullanılacak "zoom" boyutu.

    func windowWillUseStandardFrame(
        _ window: NSWindow,
        defaultFrame newFrame: NSRect
    ) -> NSRect {

        guard
            let screen =
                window.screen ?? NSScreen.main
        else {
            return newFrame
        }

        return screen.visibleFrame
    }

    // MARK: - Window Delegate

    func windowDidBecomeKey(
        _ notification: Notification
    ) {
        // Burada pencere boyutuna müdahale etmiyoruz.
    }

    // MARK: - Application

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {

        return true
    }
}
