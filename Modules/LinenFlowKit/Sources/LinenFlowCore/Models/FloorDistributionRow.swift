import Foundation

public struct FloorDistributionRow: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var floorNumber: Int
    public var itemName: String
    public var suggestedPieces: Int
    public var suggestedBundles: Int?
    public var actualPieces: Int?
    public var actualBundles: Int?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        floorNumber: Int,
        itemName: String,
        suggestedPieces: Int,
        suggestedBundles: Int? = nil,
        actualPieces: Int? = nil,
        actualBundles: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.floorNumber = floorNumber
        self.itemName = itemName
        self.suggestedPieces = suggestedPieces
        self.suggestedBundles = suggestedBundles
        self.actualPieces = actualPieces
        self.actualBundles = actualBundles
        self.notes = notes
    }
}
