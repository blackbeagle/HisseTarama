import Cocoa

class DetailViewController: NSViewController {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var contentTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.stringValue = "Select an item"
        contentTextField.stringValue = ""
    }
    
    func didSelectSidebarItem(_ item: SidebarItem) {

        titleLabel.stringValue = item.title

        // Eğer bir hisse ise (children yoksa),
        // gelecekte burada detayları yükleriz
        if item.children == nil {

            contentTextField.stringValue =
                "Details for \(item.title) will be shown here.\n" +
                "Price, charts, technicals..."

        } else {

            contentTextField.stringValue =
                "Group: \(item.title)\n" +
                "Select a stock to see details."
        }
    }
}
