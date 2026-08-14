import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // Storyboard tarafından oluşturulan ana pencere
    //@IBOutlet weak var window: NSWindow!

    // MARK: - Application Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Insert code here to initialize your application
    }


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

    func windowDidBecomeKey(_ notification: Notification) {
        // Burada pencere boyutuna müdahale etmiyoruz.
    }

    // MARK: - Application

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {

        return true
    }
}
