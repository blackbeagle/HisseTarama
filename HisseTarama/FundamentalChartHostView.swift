import Cocoa

final class FundamentalChartHostView: NSView {

    private let renderer: RevenueCostChartRenderer

    private var data: [RevenueCostChartRenderer.DataPoint] = []
    private var isUSDMode = false

    init(renderer: RevenueCostChartRenderer = RevenueCostChartRenderer()) {
        self.renderer = renderer

        super.init(frame: .zero)

        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        renderer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(renderer)

        NSLayoutConstraint.activate([
            renderer.leadingAnchor.constraint(equalTo: leadingAnchor),
            renderer.trailingAnchor.constraint(equalTo: trailingAnchor),
            renderer.topAnchor.constraint(equalTo: topAnchor),
            renderer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        self.renderer = RevenueCostChartRenderer()

        super.init(coder: coder)

        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        renderer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(renderer)

        NSLayoutConstraint.activate([
            renderer.leadingAnchor.constraint(equalTo: leadingAnchor),
            renderer.trailingAnchor.constraint(equalTo: trailingAnchor),
            renderer.topAnchor.constraint(equalTo: topAnchor),
            renderer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func setData(_ data: [RevenueCostChartRenderer.DataPoint]) {
        self.data = data

        renderer.setData(data)

        if isUSDMode {
            renderer.setCurrency(isUSD: true)
        } else {
            renderer.setCurrency(isUSD: false)
        }

        needsDisplay = true
    }

    func setCurrency(isUSD: Bool) {
        isUSDMode = isUSD
        renderer.setCurrency(isUSD: isUSD)
        needsDisplay = true
    }

    func clear() {
        data.removeAll()

        renderer.setData([])

        needsDisplay = true
    }

    override func layout() {
        super.layout()

        renderer.frame = bounds
    }
}
