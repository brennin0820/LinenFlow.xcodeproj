import Foundation

struct ElevatorTrip: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var sequence: Int
    var primaryItemName: String
    var secondaryItemName: String?
    var estimatedBundles: Int
    var strategyNote: String
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        sequence: Int,
        primaryItemName: String,
        secondaryItemName: String? = nil,
        estimatedBundles: Int,
        strategyNote: String,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.sequence = sequence
        self.primaryItemName = primaryItemName
        self.secondaryItemName = secondaryItemName
        self.estimatedBundles = estimatedBundles
        self.strategyNote = strategyNote
        self.isCompleted = isCompleted
    }

    var title: String {
        if let secondaryItemName {
            return "\(primaryItemName) + \(secondaryItemName)"
        }
        return primaryItemName
    }
}
