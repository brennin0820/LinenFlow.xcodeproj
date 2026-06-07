import Foundation

struct FloorDistributionRow: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var floorNumber: Int
    var itemName: String
    var suggestedPieces: Int
    var suggestedBundles: Int?
    var actualPieces: Int?
    var actualBundles: Int?
    var notes: String?

    init(
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
