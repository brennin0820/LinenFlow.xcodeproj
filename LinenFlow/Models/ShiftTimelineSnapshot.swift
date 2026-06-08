import Foundation

struct ShiftTimelineSnapshot: Equatable, Sendable {
    let shiftDate: Date
    let phases: [PhaseWindow]
    let primaryAnchor: Date

    struct PhaseWindow: Equatable, Sendable {
        let phase: ShiftTimelinePhase
        let start: Date
        let end: Date

        var isPointEvent: Bool { start == end }

        func contains(_ date: Date) -> Bool {
            if isPointEvent {
                return date >= start
            }
            return date >= start && date < end
        }
    }

    func window(for phase: ShiftTimelinePhase) -> PhaseWindow? {
        phases.first { $0.phase == phase }
    }

    func currentPhase(at now: Date) -> ShiftTimelinePhase {
        guard let first = phases.first, now >= first.start else { return .idle }

        if let active = phases.last(where: { $0.contains(now) }) {
            return active.phase
        }

        if let last = phases.last, now >= last.end {
            return last.phase
        }

        return .idle
    }

    func nextTransition(after now: Date) -> PhaseWindow? {
        phases.first { $0.start > now }
    }

    func progressFraction(at now: Date) -> Double {
        guard let wake = window(for: .wake), let shiftEnd = window(for: .shiftEnd) else { return 0 }
        let spanStart = wake.start
        let spanEnd = shiftEnd.end
        guard spanEnd > spanStart else { return 0 }
        let raw = now.timeIntervalSince(spanStart) / spanEnd.timeIntervalSince(spanStart)
        return min(max(raw, 0), 1)
    }
}
