import Foundation

struct RebalanceSuggestion: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var itemName: String
    var message: String
    var donorFloors: [Int]
    var targetFloors: [Int]
    var piecesRecovered: Int
    var isRecoverable: Bool

    init(
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
