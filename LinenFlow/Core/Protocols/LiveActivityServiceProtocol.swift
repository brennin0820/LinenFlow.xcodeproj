import Foundation

struct ShiftActivityContent: Equatable, Sendable {
    var shiftName: String
    var clockInTime: Date
    var currentPhase: ShiftTimelinePhase
    var nextActionLabel: String
    var nextActionTime: Date
    var progressFraction: Double
    var statusEmoji: String
}

protocol LiveActivityServiceProtocol: Sendable {
    func start(initialContent: ShiftActivityContent) async throws -> String
    func update(activityID: String, content: ShiftActivityContent) async
    func end(activityID: String, finalContent: ShiftActivityContent) async
    var canStartFromBackground: Bool { get }
}
