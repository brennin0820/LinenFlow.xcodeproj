import Foundation

public struct AcknowledgementState: Codable, Equatable {
    public var acknowledgedPhases: Set<ShiftTimelinePhase>

    public init(acknowledgedPhases: Set<ShiftTimelinePhase> = []) {
        self.acknowledgedPhases = acknowledgedPhases
    }

    public mutating func acknowledge(_ phase: ShiftTimelinePhase) {
        acknowledgedPhases.insert(phase)
    }

    public func isAcknowledged(_ phase: ShiftTimelinePhase) -> Bool {
        acknowledgedPhases.contains(phase)
    }
}
