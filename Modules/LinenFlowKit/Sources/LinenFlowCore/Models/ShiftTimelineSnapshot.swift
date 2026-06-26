import Foundation

public struct ShiftTimelineSnapshot {
    public let shiftDate: Date
    public let phases: [PhaseWindow]
    public let primaryAnchor: Date

    public struct PhaseWindow: Equatable {
        public let phase: ShiftTimelinePhase
        public let start: Date
        public let end: Date

        public var durationIsZero: Bool {
            start == end
        }

        public var isPointEvent: Bool { durationIsZero }
    }

    /// Current phase given a point in time.
    public func currentPhase(at now: Date) -> ShiftTimelinePhase {
        let ordered = phases.sorted { $0.start < $1.start }

        for (index, window) in ordered.enumerated() {
            if window.durationIsZero {
                if now >= window.start {
                    let nextStart = ordered.dropFirst(index + 1).first?.start
                    if nextStart == nil || now < nextStart! {
                        return window.phase
                    }
                }
                continue
            }

            if now >= window.start && now < window.end {
                return window.phase
            }
        }

        if let last = ordered.last, now >= last.end {
            return last.phase
        }

        if let first = ordered.first, now < first.start {
            return .idle
        }

        return .idle
    }

    /// Next phase transition boundary after `now`.
    public func nextTransition(after now: Date) -> PhaseWindow? {
        let ordered = phases.sorted { $0.start < $1.start }
        return ordered.first { $0.start > now || ($0.end > now && !$0.durationIsZero) }
    }

    public func window(for phase: ShiftTimelinePhase) -> PhaseWindow? {
        phases.first { $0.phase == phase }
    }

    public func progressFraction(at now: Date) -> Double {
        guard let wake = window(for: .wake), let shiftEnd = window(for: .shiftEnd) else { return 0 }
        let spanStart = wake.start
        let spanEnd = shiftEnd.end
        guard spanEnd > spanStart else { return 0 }
        let raw = now.timeIntervalSince(spanStart) / spanEnd.timeIntervalSince(spanStart)
        return min(max(raw, 0), 1)
    }
}
