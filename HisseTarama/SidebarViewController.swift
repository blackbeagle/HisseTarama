import Cocoa

class SidebarViewController: NSViewController {

    @IBOutlet weak var outlineView: NSOutlineView!
    
    weak var selectionDelegate: SidebarSelectionDelegate?
    
    private let viewModel = SidebarViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        outlineView.dataSource = self
        outlineView.delegate = self
    
        // İlk açılışta tüm öğeleri genişlet (isteğe bağlı)
        outlineView.expandItem(nil, expandChildren: true)
    
    }
    
 
}

extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? SidebarItem {
            return item.children?.count ?? 0
        }
        return viewModel.items.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? SidebarItem {
            return item.children![index]
        }
        return viewModel.items[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let item = item as? SidebarItem {
            return item.children != nil && !item.children!.isEmpty
        }
        return false
    }
}

extension SidebarViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) as? NSTableCellView
        let sidebarItem = item as! SidebarItem
        cell?.textField?.stringValue = sidebarItem.name
        return cell
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
            let selectedRow = outlineView.selectedRow
            if selectedRow >= 0,  // -1 olmadığından emin ol
               let item = outlineView.item(atRow: selectedRow) as? SidebarItem {
                selectionDelegate?.didSelectSidebarItem(item)
            }
        }

}
