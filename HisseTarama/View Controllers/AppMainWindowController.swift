// AppMainWindowController.swift

import Cocoa

class AppMainWindowController: NSWindowController {

    // MARK: - Properties

    private var mainSplitViewController:
        MainSplitViewController?

    private var sidebarButton:
        NSButton?

    // MARK: - Window Lifecycle

    override func windowDidLoad() {

        super.windowDidLoad()

        // Açılışta pencere büyük olsun
        window?.zoom(nil)

        // MainSplitViewController'a ulaş
        if let splitViewController =
            window?.contentViewController
            as? MainSplitViewController {

            mainSplitViewController =
                splitViewController
        }

        // Sidebar genişliğini başlangıçta ayarla
        DispatchQueue.main.async { [weak self] in

            self?.mainSplitViewController?
                .adjustSidebarWidthManually()

            self?.setupSidebarButton()
        }
    }

    // MARK: - Sidebar Button

    private func setupSidebarButton() {

        guard let window = window else {
            return
        }

        // Daha önce eklenmişse tekrar ekleme
        if sidebarButton != nil {
            return
        }

        let button = NSButton()

        button.setButtonType(.momentaryPushIn)

        button.isBordered = false

        button.bezelStyle = .texturedRounded

        button.imagePosition = .imageOnly

        button.imageScaling = .scaleProportionallyDown

        button.toolTip = "Sidebar'ı Göster/Gizle"

        button.target = self

        button.action = #selector(sidebarButtonClicked(_:))

        if #available(macOS 11.0, *) {

            let symbolConfiguration =
                NSImage.SymbolConfiguration(
                    pointSize: 18,
                    weight: .medium
                )

            button.image =
                NSImage(
                    systemSymbolName: "sidebar.left",
                    accessibilityDescription:
                        "Sidebar'ı Göster/Gizle"
                )?.withSymbolConfiguration(
                    symbolConfiguration
                )
        }

        button.translatesAutoresizingMaskIntoConstraints = false

        let containerView =
            NSView(
                frame:
                    NSRect(
                        x: 0,
                        y: 0,
                        width: 28,
                        height: 28
                    )
            )

        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(button)

        NSLayoutConstraint.activate([

            button.centerXAnchor.constraint(
                equalTo:
                    containerView.centerXAnchor
            ),

            button.centerYAnchor.constraint(
                equalTo:
                    containerView.centerYAnchor
            ),

            button.widthAnchor.constraint(
                equalToConstant: 30
            ),

            button.heightAnchor.constraint(
                equalToConstant: 30
            )
        ])

        let accessory =
            NSTitlebarAccessoryViewController()

        accessory.view =
            containerView

        accessory.layoutAttribute =
            .left

        window.addTitlebarAccessoryViewController(
            accessory
        )

        sidebarButton = button

        updateSidebarButtonState()
    }

    // MARK: - Sidebar Action

    @objc private func sidebarButtonClicked(
        _ sender: NSButton
    ) {

        mainSplitViewController?
            .toggleSidebar()

        DispatchQueue.main.async { [weak self] in

            self?.updateSidebarButtonState()
        }
    }

    // MARK: - Sidebar Button State

    private func updateSidebarButtonState() {

        guard
            let button = sidebarButton,
            let splitViewController =
                mainSplitViewController,
            let sidebarItem =
                splitViewController.splitViewItems.first
        else {
            return
        }

        if sidebarItem.isCollapsed {

            button.toolTip =
                "Sidebar'ı Göster"

        } else {

            button.toolTip =
                "Sidebar'ı Gizle"
        }
    }

    // MARK: - Public Sidebar Toggle

    func toggleSidebar() {

        mainSplitViewController?
            .toggleSidebar()

        DispatchQueue.main.async { [weak self] in

            self?.updateSidebarButtonState()
        }
    }
}
