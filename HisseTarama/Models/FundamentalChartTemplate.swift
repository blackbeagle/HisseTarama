import Foundation

// MARK: - Fundamental Chart Template

struct FundamentalChartTemplate {

    // MARK: - Chart Type

    enum ChartType {

        /// Tek bir finansal kalemin standart sütun grafiği.
        case standard

        /// Satış Gelirleri / Satışların Maliyeti /
        /// Brüt Kâr kompozisyon grafiği.
        case revenueCost

        /// Yurtiçi / Yurtdışı satışların
        /// toplam içindeki dağılım grafiği.
        case domesticExportSales
    }

    // MARK: - Properties

    let id: String

    let title: String

    let group:
        FundamentalGroup

    let chartTypes:
        [ChartType]

    // MARK: - Initialization

    init(
        id:
            String,
        title:
            String,
        group:
            FundamentalGroup,
        chartTypes:
            [ChartType]
    ) {

        self.id =
            id

        self.title =
            title

        self.group =
            group

        self.chartTypes =
            chartTypes
    }
}

// MARK: - Predefined Templates

extension FundamentalChartTemplate {

    /// Satışlar dashboard şablonu.
    ///
    /// İçerdiği grafikler:
    ///
    /// 1. Satış Gelirleri /
    ///    Satışların Maliyeti /
    ///    Brüt Kâr
    ///
    /// 2. Yurtiçi Satışlar /
    ///    Yurtdışı Satışlar
    ///
    static let sales =
        FundamentalChartTemplate(
            id:
                "sales",

            title:
                "Satışlar",

            group:
                .sales,

            chartTypes: [

                .revenueCost,

                .domesticExportSales
            ]
        )

    // MARK: - All Templates

    /// Uygulamada tanımlı tüm grafik şablonları.
    ///
    /// Yeni grup şablonları eklendikçe
    /// buraya eklenecek.
    static let all:
        [FundamentalChartTemplate] = [

            .sales
        ]

    // MARK: - Lookup

    /// Verilen grubun grafik şablonunu bulur.
    static func template(
        for group:
            FundamentalGroup
    ) -> FundamentalChartTemplate? {

        all.first {
            $0.group.id ==
                group.id
        }
    }

    /// Verilen finansal kalemin ait olduğu
    /// grafik şablonunu bulur.
    static func template(
        containing itemCode:
            String
    ) -> FundamentalChartTemplate? {

        guard
            let group =
                FundamentalGroup.group(
                    containing:
                        itemCode
                )
        else {
            return nil
        }

        return template(
            for:
                group
        )
    }
}


