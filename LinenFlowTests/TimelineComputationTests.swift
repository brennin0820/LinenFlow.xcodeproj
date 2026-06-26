import Foundation
import XCTest
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class TimelineComputationTests: XCTestCase {

    private var easternCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)!
    }

    private func defaultSettings(
        sleepMinutes: Int = 480,
        commuteMinutes: Int = 30,
        getReadyMinutes: Int = 45,
        walkToCarMinutes: Int = 5,
        parkingWalkMinutes: Int = 10,
        walkInMinutes: Int = 5,
        arrivalBufferMinutes: Int = 15,
        preSleepMinutes: Int = 30
    ) -> ShiftPlannerSettings {
        ShiftPlannerSettings(
            sleepDurationMinutes: sleepMinutes,
            getReadyDurationMinutes: getReadyMinutes,
            walkToCarMinutes: walkToCarMinutes,
            commuteDurationMinutes: commuteMinutes,
            parkingWalkMinutes: parkingWalkMinutes,
            walkInMinutes: walkInMinutes,
            arrivalBufferMinutes: arrivalBufferMinutes,
            preSleepWindDownMinutes: preSleepMinutes
        )
    }

    // MARK: - Standard night shift

    func testStandardNightShiftPhaseBoundaries() {
        let calendar = easternCalendar
        let clockIn = date(year: 2024, month: 3, day: 11, hour: 23, minute: 0, calendar: calendar)
        let settings = defaultSettings()
        let snapshot = computeTimeline(
            clockInTime: clockIn,
            settings: settings,
            shiftDurationMinutes: 480,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.primaryAnchor, clockIn)

        guard
            let sleep = snapshot.window(for: .sleep),
            let wake = snapshot.window(for: .wake),
            let getReady = snapshot.window(for: .getReady),
            let leave = snapshot.window(for: .leave),
            let commute = snapshot.window(for: .commute),
            let arrival = snapshot.window(for: .arrival),
            let preSleep = snapshot.window(for: .preSleep)
        else {
            return XCTFail("Missing expected phase windows")
        }

        XCTAssertTrue(
            calendarMinuteSpan(from: sleep.start, minutes: 480, to: wake.start, calendar: calendar),
            "Sleep should span 8 hours"
        )
        XCTAssertTrue(
            calendarMinuteSpan(from: getReady.start, minutes: 45, to: getReady.end, calendar: calendar)
        )
        XCTAssertTrue(
            calendarMinuteSpan(from: commute.start, minutes: 30, to: commute.end, calendar: calendar)
        )
        XCTAssertEqual(leave.start, commute.start)
        XCTAssertEqual(wake.start, getReady.start)
        XCTAssertEqual(arrival.end, clockIn)
        XCTAssertTrue(preSleep.start < sleep.start)
        XCTAssertTrue(sleep.start < clockIn, "Sleep block should precede clock-in anchor")
    }

    // MARK: - DST spring-forward (March 10, 2024)

    func testDSTSpringForwardSleepDurationRemainsEightHours() {
        let calendar = easternCalendar
        let clockIn = date(year: 2024, month: 3, day: 10, hour: 6, minute: 0, calendar: calendar)
        let settings = defaultSettings(sleepMinutes: 480)
        let snapshot = computeTimeline(
            clockInTime: clockIn,
            settings: settings,
            shiftDurationMinutes: 480,
            calendar: calendar
        )

        guard let sleep = snapshot.window(for: .sleep), let wake = snapshot.window(for: .wake) else {
            return XCTFail("Missing sleep or wake window")
        }

        XCTAssertTrue(
            calendarMinuteSpan(from: sleep.start, minutes: 480, to: wake.start, calendar: calendar),
            "Sleep must remain 480 calendar minutes across spring-forward"
        )
    }

    // MARK: - DST fall-back (November 3, 2024)

    func testDSTFallBackSleepDurationRemainsEightHours() {
        let calendar = easternCalendar
        let clockIn = date(year: 2024, month: 11, day: 3, hour: 6, minute: 0, calendar: calendar)
        let settings = defaultSettings(sleepMinutes: 480)
        let snapshot = computeTimeline(
            clockInTime: clockIn,
            settings: settings,
            shiftDurationMinutes: 480,
            calendar: calendar
        )

        guard let sleep = snapshot.window(for: .sleep), let wake = snapshot.window(for: .wake) else {
            return XCTFail("Missing sleep or wake window")
        }

        XCTAssertTrue(
            calendarMinuteSpan(from: sleep.start, minutes: 480, to: wake.start, calendar: calendar),
            "Sleep must remain 480 calendar minutes across fall-back"
        )
    }

    // MARK: - Midnight crossing

    func testMidnightCrossingPrepPhasesOnPriorCalendarDay() {
        let calendar = easternCalendar
        // 1:00 AM clock-in: backward chain crosses midnight into the prior calendar day.
        let clockIn = date(year: 2024, month: 6, day: 16, hour: 1, minute: 0, calendar: calendar)
        let settings = defaultSettings()
        let snapshot = computeTimeline(
            clockInTime: clockIn,
            settings: settings,
            shiftDurationMinutes: 480,
            calendar: calendar
        )

        guard
            let sleep = snapshot.window(for: .sleep),
            let preSleep = snapshot.window(for: .preSleep),
            let getReady = snapshot.window(for: .getReady)
        else {
            return XCTFail("Missing phase windows")
        }

        let clockInDay = calendar.startOfDay(for: clockIn)
        XCTAssertTrue(preSleep.start < clockInDay)
        XCTAssertTrue(sleep.start < clockInDay)
        XCTAssertTrue(getReady.start < clockInDay)
        XCTAssertEqual(snapshot.primaryAnchor, clockIn)
    }

    // MARK: - Zero commute

    func testZeroCommuteCollapsesTransitPhases() {
        let calendar = easternCalendar
        let clockIn = date(year: 2024, month: 6, day: 15, hour: 7, minute: 0, calendar: calendar)
        let settings = defaultSettings(
            commuteMinutes: 0,
            walkToCarMinutes: 0,
            parkingWalkMinutes: 0,
            walkInMinutes: 0,
            arrivalBufferMinutes: 15
        )
        let snapshot = computeTimeline(
            clockInTime: clockIn,
            settings: settings,
            shiftDurationMinutes: 480,
            calendar: calendar
        )

        guard
            let leave = snapshot.window(for: .leave),
            let commute = snapshot.window(for: .commute),
            let parking = snapshot.window(for: .parking),
            let walkToCar = snapshot.window(for: .walkToCar),
            let getReady = snapshot.window(for: .getReady)
        else {
            return XCTFail("Missing transit phase windows")
        }

        XCTAssertEqual(leave.start, commute.start)
        XCTAssertEqual(commute.start, commute.end)
        XCTAssertEqual(parking.start, parking.end)
        XCTAssertEqual(walkToCar.end, leave.start)
        XCTAssertTrue(getReady.end <= leave.start)
        XCTAssertTrue(phasesHaveNoOverlap(snapshot.phases))
    }

    // MARK: - Very long commute (120 min)

    func testVeryLongCommuteHasNoPhaseOverlap() {
        let calendar = easternCalendar
        let clockIn = date(year: 2024, month: 6, day: 15, hour: 8, minute: 0, calendar: calendar)
        let settings = defaultSettings(commuteMinutes: 120)
        let snapshot = computeTimeline(
            clockInTime: clockIn,
            settings: settings,
            shiftDurationMinutes: 480,
            calendar: calendar
        )

        guard let commute = snapshot.window(for: .commute) else {
            return XCTFail("Missing commute window")
        }

        XCTAssertTrue(
            calendarMinuteSpan(from: commute.start, minutes: 120, to: commute.end, calendar: calendar)
        )
        XCTAssertTrue(phasesHaveNoOverlap(snapshot.phases))

        let ordered = snapshot.phases.filter { $0.start < $0.end }.sorted { $0.start < $1.start }
        for index in 0 ..< ordered.count - 1 {
            XCTAssertLessThanOrEqual(
                ordered[index].end,
                ordered[index + 1].start,
                "Phase \(ordered[index].phase) overlaps \(ordered[index + 1].phase)"
            )
        }
    }
}
