import Foundation

// MARK: - Fundamental Group

struct FundamentalGroup {

    let id: String
    let title: String
    let itemCodes: [String]

    init(
        id: String,
        title: String,
        itemCodes: [String]
    ) {
        self.id = id
        self.title = title
        self.itemCodes = itemCodes
    }

    // MARK: - Group Membership

    func contains(
        itemCode: String
    ) -> Bool {

        itemCodes.contains(
            itemCode
        )
    }
}

// MARK: - Predefined Groups

extension FundamentalGroup {

    /// Satışlarla ilgili finansal kalemler.
    ///
    /// Satış Gelirleri
    /// Satışların Maliyeti
    /// Yurtiçi Satışlar
    /// Yurtdışı Satışlar
    static let sales =
        FundamentalGroup(
            id:
                "sales",
            title:
                "Satışlar",
            itemCodes: [
                "3C",
                "3CA",
                "4BC",
                "4BD"
            ]
        )

    /// Uygulamada tanımlı tüm gruplar.
    ///
    /// Yeni gruplar eklendikçe buraya
    /// eklenecek.
    static let all: [FundamentalGroup] = [
        .sales
    ]

    // MARK: - Lookup

    /// Verilen finansal kalemin ait olduğu
    /// grubu bulur.
    static func group(
        containing itemCode: String
    ) -> FundamentalGroup? {

        all.first {
            $0.contains(
                itemCode:
                    itemCode
            )
        }
    }
}


