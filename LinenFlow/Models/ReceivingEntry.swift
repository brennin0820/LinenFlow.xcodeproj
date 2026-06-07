import Foundation

struct ReceivingEntry: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var itemName: String
    var countMethod: CountMethod
    var binCount: Int?
    var physicalBinCount: Int?
    var manualPieces: Int?
    var piecesPerBin: Int?
    var calculatedPieces: Int
    var calculatedFullBundles: Int
    var loosePieces: Int
    var notes: String?

    init(
        id: UUID = UUID(),
        itemName: String,
        countMethod: CountMethod,
        binCount: Int? = nil,
        physicalBinCount: Int? = nil,
        manualPieces: Int? = nil,
        piecesPerBin: Int? = nil,
        calculatedPieces: Int = 0,
        calculatedFullBundles: Int = 0,
        loosePieces: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.itemName = itemName
        self.countMethod = countMethod
        self.binCount = binCount
        self.physicalBinCount = physicalBinCount
        self.manualPieces = manualPieces
        self.piecesPerBin = piecesPerBin
        self.calculatedPieces = calculatedPieces
        self.calculatedFullBundles = calculatedFullBundles
        self.loosePieces = loosePieces
        self.notes = notes
    }
}
