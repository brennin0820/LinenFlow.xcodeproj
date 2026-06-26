import Foundation

public struct ReceivingEntry: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var itemName: String
    public var countMethod: CountMethod
    public var binCount: Int?
    public var physicalBinCount: Int?
    public var manualPieces: Int?
    public var piecesPerBin: Int?
    public var calculatedPieces: Int
    public var calculatedFullBundles: Int
    public var loosePieces: Int
    public var notes: String?

    public init(
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
