import Foundation

struct ScanResult: Identifiable {

    let id: UUID

    let stock: Stock

    let scanID: UUID

    let scannedAt: Date

    init(
        id: UUID = UUID(),
        stock: Stock,
        scanID: UUID,
        scannedAt: Date = Date()
    ) {
        self.id = id
        self.stock = stock
        self.scanID = scanID
        self.scannedAt = scannedAt
    }
}
