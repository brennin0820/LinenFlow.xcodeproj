import Foundation

private let shiftCountdownLeadMinutes = 5

/// Computes the full phase timeline for a shift using calendar-safe date arithmetic.
func computeTimeline(
    clockInTime: Date,
    settings: ShiftPlannerSettings,
    shiftDurationMinutes: Int,
    calendar: Calendar = .autoupdatingCurrent
) -> ShiftTimelineSnapshot {
    func subtractMinutes(_ minutes: Int, from date: Date) -> Date {
        guard minutes > 0 else { return date }
        guard let result = calendar.date(byAdding: DateComponents(minute: -minutes), to: date) else {
            preconditionFailure("Calendar failed subtracting \(minutes) minutes")
        }
        return result
    }

    func addMinutes(_ minutes: Int, to date: Date) -> Date {
        guard minutes > 0 else { return date }
        guard let result = calendar.date(byAdding: DateComponents(minute: minutes), to: date) else {
            preconditionFailure("Calendar failed adding \(minutes) minutes")
        }
        return result
    }

    // Backward from clock-in anchor
    let arrivalStart = subtractMinutes(settings.arrivalBufferMinutes, from: clockInTime)
    let walkInStart = subtractMinutes(settings.walkInMinutes, from: arrivalStart)
    let parkingStart = subtractMinutes(settings.parkingWalkMinutes, from: walkInStart)
    let commuteStart = subtractMinutes(settings.commuteDurationMinutes, from: parkingStart)
    let leaveStart = commuteStart
    let walkToCarStart = subtractMinutes(settings.walkToCarMinutes, from: leaveStart)
    let getReadyStart = subtractMinutes(settings.getReadyDurationMinutes, from: walkToCarStart)
    let wakeStart = getReadyStart
    let sleepStart = subtractMinutes(settings.sleepDurationMinutes, from: wakeStart)
    let preSleepStart = subtractMinutes(settings.preSleepWindDownMinutes, from: sleepStart)

    // Forward from clock-in anchor
    let shiftCountdownStart = subtractMinutes(shiftCountdownLeadMinutes, from: clockInTime)
    let shiftActiveEnd = addMinutes(shiftDurationMinutes, to: clockInTime)
    let shiftEndStart = shiftActiveEnd
    let beDownEnd = addMinutes(settings.beDownMinutesAfterShift, to: shiftEndStart)

    let phases: [ShiftTimelineSnapshot.PhaseWindow] = [
        .init(phase: .preSleep, start: preSleepStart, end: sleepStart),
        .init(phase: .sleep, start: sleepStart, end: wakeStart),
        .init(phase: .wake, start: wakeStart, end: wakeStart),
        .init(phase: .getReady, start: getReadyStart, end: walkToCarStart),
        .init(phase: .walkToCar, start: walkToCarStart, end: leaveStart),
        .init(phase: .leave, start: leaveStart, end: leaveStart),
        .init(phase: .commute, start: commuteStart, end: parkingStart),
        .init(phase: .parking, start: parkingStart, end: walkInStart),
        .init(phase: .walkIn, start: walkInStart, end: arrivalStart),
        .init(phase: .arrival, start: arrivalStart, end: clockInTime),
        .init(phase: .shiftCountdown, start: shiftCountdownStart, end: clockInTime),
        .init(phase: .shiftActive, start: clockInTime, end: shiftActiveEnd),
        .init(phase: .shiftEnd, start: shiftEndStart, end: shiftEndStart),
        .init(phase: .beDown, start: shiftEndStart, end: beDownEnd),
    ]

    let shiftDate = calendar.startOfDay(for: clockInTime)

    return ShiftTimelineSnapshot(
        shiftDate: shiftDate,
        phases: phases,
        primaryAnchor: clockInTime
    )
}

/// Returns true when prep/transit phase windows do not overlap (excludes arrival vs shiftCountdown at clock-in).
func phasesHaveNoOverlap(_ phases: [ShiftTimelineSnapshot.PhaseWindow]) -> Bool {
    let overlappingAllowed: Set<ShiftTimelinePhase> = [.arrival, .shiftCountdown, .beDown, .shiftActive]
    let timedPhases = phases
        .filter { $0.start < $0.end && !overlappingAllowed.contains($0.phase) }
        .sorted { $0.start < $1.start }

    for index in 0 ..< timedPhases.count - 1 {
        if timedPhases[index].end > timedPhases[index + 1].start {
            return false
        }
    }
    return true
}

/// Verifies that adding `minutes` via the calendar from `start` reaches `end`.
func calendarMinuteSpan(
    from start: Date,
    minutes: Int,
    to end: Date,
    calendar: Calendar
) -> Bool {
    guard let computed = calendar.date(byAdding: DateComponents(minute: minutes), to: start) else {
        return false
    }
    return computed == end
}
