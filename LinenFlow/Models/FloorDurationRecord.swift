import Foundation

struct FloorDurationRecord: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var floorNumber: Int
    var startedAt: Date
    var endedAt: Date
    var durationSeconds: TimeInterval

    init(
        id: UUID = UUID(),
        floorNumber: Int,
        startedAt: Date,
        endedAt: Date
    ) {
        self.id = id
        self.floorNumber = floorNumber
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = max(0, endedAt.timeIntervalSince(startedAt))
    }
}
