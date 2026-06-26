import Foundation

public struct FloorStepRecord: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var floorNumber: Int
    public var steps: Int
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        floorNumber: Int,
        steps: Int = 0,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.floorNumber = floorNumber
        self.steps = max(0, steps)
        self.updatedAt = updatedAt
    }
}
