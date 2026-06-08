import Foundation

struct AcknowledgementState: Codable, Equatable, Sendable {
    var acknowledgedPhases: Set<ShiftTimelinePhase> = []

    mutating func acknowledge(_ phase: ShiftTimelinePhase) {
        acknowledgedPhases.insert(phase)
    }

    func isAcknowledged(_ phase: ShiftTimelinePhase) -> Bool {
        acknowledgedPhases.contains(phase)
    }

    mutating func reset() {
        acknowledgedPhases.removeAll()
    }
}
