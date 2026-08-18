
import Foundation

protocol SidebarSelectionDelegate: AnyObject {

    func sidebar(
        _ sidebar: SidebarViewController,
        didSelect selection: SidebarSelection
    )
}
