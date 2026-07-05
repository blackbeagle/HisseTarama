import Cocoa

class DetailViewController: NSViewController, SidebarSelectionDelegate {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var contentTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.stringValue = "Select an item"
        contentTextField.stringValue = ""
    }
    
    func didSelectSidebarItem(_ item: SidebarItem) {
        titleLabel.stringValue = item.name
        
        // Eğer bir hisse ise (children yoksa), gelecekte burada detayları yükleriz
        if item.children == nil {
            contentTextField.stringValue = "Details for \(item.name) will be shown here.\nPrice, charts, technicals..."
        } else {
            contentTextField.stringValue = "Group: \(item.name)\nSelect a stock to see details."
        }
    }
}
