import Cocoa

final class FundamentalsViewController: NSViewController {

    private let selectedStockLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "Hisse seçilmedi"
        )

        label.alignment = .center
        label.font = NSFont.systemFont(
            ofSize: 24,
            weight: .medium
        )

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    private func setupView() {

        view.addSubview(
            selectedStockLabel
        )

        NSLayoutConstraint.activate([

            selectedStockLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            selectedStockLabel.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            )
        ])
    }

    // MARK: - Stock Selection

    func selectStock(symbol: String) {

        selectedStockLabel.stringValue =
            "\(symbol) seçildi"
    }
}
