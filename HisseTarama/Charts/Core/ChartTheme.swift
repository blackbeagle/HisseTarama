import Cocoa

struct ChartTheme {
    
    var showGrid = true
    var showCrosshair = true
    var showPriceLabel = true
    var showTooltip = true
    var showAxisTitles = true

    // MARK: - Background

    let backgroundColor: NSColor

    // MARK: - Candle Colors

    let bullColor: NSColor
    let bearColor: NSColor

    // MARK: - Grid

    let gridColor: NSColor

    // MARK: - Axis

    let axisLabelColor: NSColor
    let axisTitleColor: NSColor

    // MARK: - Crosshair

    let crosshairColor: NSColor

    // MARK: - Selection

    let selectionFillColor: NSColor
    let selectionBorderColor: NSColor

    // MARK: - Price Label

    let priceLabelBackground: NSColor
    let priceLabelText: NSColor

    // MARK: - SMA Colors

    let smaColors: [Int: NSColor]

    // MARK: - Dimensions

    let gridLineWidth: CGFloat
    let candleLineWidth: CGFloat
    let smaLineWidth: CGFloat
    let crosshairWidth: CGFloat

    // MARK: - Singleton

    static let `default` = ChartTheme(
        backgroundColor: .controlBackgroundColor,

        bullColor: .systemGreen,
        bearColor: .systemRed,

        gridColor: .separatorColor.withAlphaComponent(0.28),

        axisLabelColor: .secondaryLabelColor,
        axisTitleColor: .tertiaryLabelColor,

        crosshairColor: .systemGray.withAlphaComponent(0.45),

        selectionFillColor: .systemYellow.withAlphaComponent(0.15),
        selectionBorderColor: .systemYellow,

        priceLabelBackground: .windowBackgroundColor,
        priceLabelText: .labelColor,

        smaColors: [

            // Günlük varsayılanlar
            8  : .systemGreen,
            34 : .systemBlue,

            // Haftalık varsayılan
            52 : .black,

            // İleride kullanılabilecekler
            21 : .systemOrange,
            89 : .systemPurple,
            144: .systemBrown,
            200: .systemPink

        ],

        gridLineWidth: 0.5,
        candleLineWidth: 1.0,
        smaLineWidth: 1.0,
        crosshairWidth: 0.8
    )
}

