import Foundation

struct FloorCompletion: Identifiable, Codable, Hashable, Sendable {
    enum Status: String, Codable, Hashable, Sendable {
        case pending
        case delivered
        case skipped
    }

    var id: Int { floorNumber }
    var floorNumber: Int
    var status: Status
    var note: String
    var completedAt: Date?
    var durationSeconds: TimeInterval?

    init(
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
