import Foundation

public struct ElevatorTrip: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var sequence: Int
    public var primaryItemName: String
    public var secondaryItemName: String?
    public var estimatedBundles: Int
    public var strategyNote: String
    public var isCompleted: Bool

    public init(
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

    public var title: String {
        if let secondaryItemName {
            return "\(primaryItemName) + \(secondaryItemName)"
        }
        return primaryItemName
    }
}
