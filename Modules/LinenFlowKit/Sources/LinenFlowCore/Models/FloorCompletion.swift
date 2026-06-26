import Foundation

public struct FloorCompletion: Identifiable, Codable, Hashable, Sendable {
    public enum Status: String, Codable, Hashable, Sendable {
        case pending
        case delivered
        case skipped
    }

    public var id: Int { floorNumber }
    public var floorNumber: Int
    public var status: Status
    public var note: String
    public var completedAt: Date?
    public var durationSeconds: TimeInterval?

    public init(
        floorNumber: Int,
        status: Status = .pending,
        note: String = "",
        completedAt: Date? = nil,
        durationSeconds: TimeInterval? = nil
    ) {
        self.floorNumber = floorNumber
        self.status = status
        self.note = note
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
    }
}
