import Foundation

enum ScanValue: Hashable {

    case number(Double)
    case text(String)
    case boolean(Bool)
}

enum ScanOperator: String, Hashable {

    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
    case equal
    case notEqual
}

struct ScanCriterion: Identifiable, Hashable {

    let id: UUID

    var field: String
    var operation: ScanOperator
    var value: ScanValue

    init(
        id: UUID = UUID(),
        field: String,
        operation: ScanOperator,
        value: ScanValue
    ) {
        self.id = id
        self.field = field
        self.operation = operation
        self.value = value
    }
}
