import Foundation

private func addMinutes(_ minutes: Int, to date: Date, calendar: Calendar) -> Date {
    guard let result = calendar.date(byAdding: DateComponents(minute: minutes), to: date) else {
        preconditionFailure("Calendar add failed for \(minutes) minutes")
    }
    return result
}

private func subtractMinutes(_ minutes: Int, from date: Date, calendar: Calendar) -> Date {
    addMinutes(-minutes, to: date, calendar: calendar)
}

/// Compute the full phase timeline for a shift (HimmerFlow spec §2).
/// All date math uses `calendar.date(byAdding:to:)` — never TimeInterval subtraction.
func computeTimeline(
    clockInTime: Date,
    settings: ShiftPlannerSettings,
    shiftDurationMinutes: Int,
    calendar: Calendar = .autoupdatingCurrent
) -> ShiftTimelineSnapshot {
    let anchor = clockInTime

    let shiftEndStart = addMinutes(shiftDurationMinutes, to: anchor, calendar: calendar)
    let beDownEnd = addMinutes(settings.beDownMinutesAfterShift, to: shiftEndStart, calendar: calendar)
    let shiftCountdownStart = subtractMinutes(5, from: anchor, calendar: calendar)

    let arrivalStart = subtractMinutes(settings.arrivalBufferMinutes, from: anchor, calendar: calendar)
    let walkInStart = subtractMinutes(settings.walkInMinutes, from: arrivalStart, calendar: calendar)
    let parkingStart = subtractMinutes(settings.parkingWalkMinutes, from: walkInStart, calendar: calendar)
    let commuteStart = subtractMinutes(settings.commuteDurationMinutes, from: parkingStart, calendar: calendar)
    let leaveTime = commuteStart
    let walkToCarStart = subtractMinutes(settings.walkToCarMinutes, from: commuteStart, calendar: calendar)
    let getReadyStart = subtractMinutes(settings.getReadyDurationMinutes, from: walkToCarStart, calendar: calendar)
    let wakeTime = getReadyStart
    let sleepStart = subtractMinutes(settings.sleepDurationMinutes, from: getReadyStart, calendar: calendar)
    let preSleepStart = subtractMinutes(settings.preSleepWindDownMinutes, from: sleepStart, calendar: calendar)

    let commuteCollapsed = settings.commuteDurationMinutes <= 0
        && settings.parkingWalkMinutes <= 0
        && settings.walkInMinutes <= 0
        && settings.arrivalBufferMinutes <= 0

    var windows: [ShiftTimelineSnapshot.PhaseWindow] = [
        .init(phase: .preSleep, start: preSleepStart, end: sleepStart),
        .init(phase: .sleep, start: sleepStart, end: getReadyStart),
        .init(phase: .wake, start: wakeTime, end: wakeTime),
        .init(phase: .getReady, start: getReadyStart, end: walkToCarStart),
        .init(phase: .walkToCar, start: walkToCarStart, end: commuteStart),
        .init(phase: .leave, start: leaveTime, end: leaveTime),
    ]

    if commuteCollapsed {
        windows.append(.init(phase: .commute, start: commuteStart, end: commuteStart))
        windows.append(.init(phase: .parking, start: commuteStart, end: commuteStart))
        windows.append(.init(phase: .walkIn, start: commuteStart, end: commuteStart))
        windows.append(.init(phase: .arrival, start: commuteStart, end: anchor))
    } else {
        windows.append(.init(phase: .commute, start: commuteStart, end: parkingStart))
        windows.append(.init(phase: .parking, start: parkingStart, end: walkInStart))
        windows.append(.init(phase: .walkIn, start: walkInStart, end: arrivalStart))
        windows.append(.init(phase: .arrival, start: arrivalStart, end: anchor))
    }

    windows.append(contentsOf: [
        .init(phase: .shiftCountdown, start: shiftCountdownStart, end: anchor),
        .init(phase: .shiftActive, start: anchor, end: shiftEndStart),
        .init(phase: .shiftEnd, start: shiftEndStart, end: shiftEndStart),
        .init(phase: .beDown, start: shiftEndStart, end: beDownEnd),
    ])

    return ShiftTimelineSnapshot(
        shiftDate: anchor,
        phases: windows.sorted { $0.phase < $1.phase },
        primaryAnchor: anchor
    )
}
