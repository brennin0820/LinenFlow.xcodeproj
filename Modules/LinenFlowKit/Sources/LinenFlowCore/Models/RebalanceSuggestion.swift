import Foundation

public struct RebalanceSuggestion: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var itemName: String
    public var message: String
    public var donorFloors: [Int]
    public var targetFloors: [Int]
    public var piecesRecovered: Int
    public var isRecoverable: Bool

    public init(
        id: UUID = UUID(),
        itemName: String,
        message: String,
        donorFloors: [Int],
        targetFloors: [Int],
        piecesRecovered: Int,
        isRecoverable: Bool
    ) {
        self.id = id
        self.itemName = itemName
        self.message = message
        self.donorFloors = donorFloors
        self.targetFloors = targetFloors
        self.piecesRecovered = piecesRecovered
        self.isRecoverable = isRecoverable
    }
}
