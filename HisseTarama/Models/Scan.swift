import Foundation

enum ScanType: String, Hashable {

    case technical
    case fundamental
}

struct Scan: Identifiable {

    let id: UUID

    var name: String
    var type: ScanType

    var criteria: [ScanCriterion]

    init(
        id: UUID = UUID(),
        name: String,
        type: ScanType,
        criteria: [ScanCriterion] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.criteria = criteria
    }
}
