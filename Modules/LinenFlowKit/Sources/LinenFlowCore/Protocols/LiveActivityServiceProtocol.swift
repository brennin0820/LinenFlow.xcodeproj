import Foundation

public struct ShiftActivityContent: Equatable, Sendable {
    public var shiftName: String
    public var clockInTime: Date
    public var currentPhase: ShiftTimelinePhase
    public var nextActionLabel: String
    public var nextActionTime: Date
    public var progressFraction: Double
    public var statusEmoji: String
}

public protocol LiveActivityServiceProtocol: Sendable {
    func start(initialContent: ShiftActivityContent) async throws -> String
    func update(activityID: String, content: ShiftActivityContent) async
    func end(activityID: String, finalContent: ShiftActivityContent) async
    var canStartFromBackground: Bool { get }
}
