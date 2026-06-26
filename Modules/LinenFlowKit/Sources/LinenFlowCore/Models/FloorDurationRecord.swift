import Foundation

public struct FloorDurationRecord: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var floorNumber: Int
    public var startedAt: Date
    public var endedAt: Date
    public var durationSeconds: TimeInterval

    public init(
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
