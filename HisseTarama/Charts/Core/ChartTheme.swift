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

    // MARK: - SMA

    /// SMA periyodu -> renk
    let smaColors: [Int: NSColor]

    /// SMA periyodu -> çizgi kalınlığı
    /// Dictionary'de bulunmayan SMA'lar genel smaLineWidth değerini kullanır.
    let smaLineWidths: [Int: CGFloat]

    /// SMA'ların varsayılan çizgi kalınlığı
    let smaLineWidth: CGFloat

    // MARK: - Dimensions

    let gridLineWidth: CGFloat
    let candleLineWidth: CGFloat
    let crosshairWidth: CGFloat

    // MARK: - Singleton

    static let `default` = ChartTheme(

        backgroundColor:
            .controlBackgroundColor,

        bullColor:
            .systemGreen,

        bearColor:
            .systemRed,

        gridColor:
            .separatorColor.withAlphaComponent(0.28),

        axisLabelColor:
            .secondaryLabelColor,

        axisTitleColor:
            .tertiaryLabelColor,

        crosshairColor:
            .systemGray.withAlphaComponent(0.75),

        selectionFillColor:
            .systemYellow.withAlphaComponent(0.15),

        selectionBorderColor:
            .systemYellow,

        priceLabelBackground:
            .windowBackgroundColor,

        priceLabelText:
            .labelColor,

        // =================================================
        // SMA RENKLERİ
        //
        // Buradaki renkleri daha sonra kendi tercihlerine
        // göre değiştirebilirsin.
        // =================================================

        smaColors: [

            // Günlük
            5: .white,
            8:
                .systemGreen,

            34:
                .systemBlue,

            // Haftalık varsayılan
            52:
                .systemOrange,

            // Diğer kullanılabilecek SMA'lar
            21:
                .systemOrange,

            89:
                .systemPurple,

            144:
                .systemBrown,

            200:
                .systemRed,
            260:
                .systemRed
        ],

        // =================================================
        // SMA ÇİZGİ KALINLIKLARI
        //
        // Dictionary'de olmayanlar smaLineWidth kullanır.
        // =================================================

        smaLineWidths: [

            // Haftalık SMA 52
            52:
                2.5,
           
            5: 0.75,
            // İstersen ileride:
            
             8: 1.25,
             34: 1.75,
            200: 2.5,
            260: 2.5
        ],

        // Genel SMA kalınlığı
        smaLineWidth:
            1.0,

        // MARK: - Dimensions

        gridLineWidth:
            0.5,

        candleLineWidth:
            1.0,

        crosshairWidth:
            1.0
    )
}
