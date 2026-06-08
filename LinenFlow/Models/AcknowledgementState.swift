import Foundation

struct AcknowledgementState: Codable, Equatable {
    var acknowledgedPhases: Set<ShiftTimelinePhase>

    init(acknowledgedPhases: Set<ShiftTimelinePhase> = []) {
        self.acknowledgedPhases = acknowledgedPhases
    }

    mutating func acknowledge(_ phase: ShiftTimelinePhase) {
        acknowledgedPhases.insert(phase)
    }

    func isAcknowledged(_ phase: ShiftTimelinePhase) -> Bool {
        acknowledgedPhases.contains(phase)
    }
}
