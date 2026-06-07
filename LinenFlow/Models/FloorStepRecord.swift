import Foundation

struct FloorStepRecord: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var floorNumber: Int
    var steps: Int
    var updatedAt: Date

    init(
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
