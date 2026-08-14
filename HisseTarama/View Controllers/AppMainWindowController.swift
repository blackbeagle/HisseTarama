import Cocoa

class AppMainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        //açılışta pencere büyük olsun diye yaptık.
        window?.zoom(nil)
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
