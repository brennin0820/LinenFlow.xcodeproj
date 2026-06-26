import Foundation
import Testing
import UserNotifications
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

@Suite("NotificationScheduling")
struct NotificationSchedulingTests {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: 0
        ))!
    }

    private func defaultSettings() -> ShiftPlannerSettings {
        ShiftPlannerSettings(
            sleepDurationMinutes: 480,
            getReadyDurationMinutes: 45,
            walkToCarMinutes: 5,
            commuteDurationMinutes: 30,
            parkingWalkMinutes: 10,
            walkInMinutes: 5,
            arrivalBufferMinutes: 15,
            preSleepWindDownMinutes: 30,
            beDownMinutesAfterShift: 60
        )
    }

    private func standardTimeline(clockIn: Date, settings: ShiftPlannerSettings) -> ShiftTimelineSnapshot {
        computeTimeline(
            clockInTime: clockIn,
            settings: settings,
            shiftDurationMinutes: 480,
            calendar: calendar
        )
    }

    private func fireDate(for request: UNNotificationRequest) -> Date? {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { return nil }
        return calendar.date(from: trigger.dateComponents)
    }

    @Test("Full shift schedules at most 64 notifications")
    func fullShiftWithinCap() {
        let settings = defaultSettings()
        let clockIn = makeDate(year: 2026, month: 1, day: 5, hour: 23, minute: 0)
        let timeline = standardTimeline(clockIn: clockIn, settings: settings)

        let requests = NotificationPlanner.requests(
            for: timeline,
            settings: settings,
            patternName: "Night",
            calendar: calendar
        )

        #expect(requests.count <= NotificationPlanner.maxPending)
        #expect(requests.count > 0)

        let wakePrimary = HimmerFlowNotificationID.make(shiftDate: clockIn, phase: .wake, isPrimary: true, calendar: calendar)
        let wakeBackup = HimmerFlowNotificationID.make(shiftDate: clockIn, phase: .wake, isPrimary: false, calendar: calendar)
        let leavePrimary = HimmerFlowNotificationID.make(shiftDate: clockIn, phase: .leave, isPrimary: true, calendar: calendar)
        let leaveBackup = HimmerFlowNotificationID.make(shiftDate: clockIn, phase: .leave, isPrimary: false, calendar: calendar)

        #expect(requests.map(\.identifier).contains(wakePrimary))
        #expect(requests.map(\.identifier).contains(wakeBackup))
        #expect(requests.map(\.identifier).contains(leavePrimary))
        #expect(requests.map(\.identifier).contains(leaveBackup))

        let wakeRequest = requests.first { $0.identifier == wakePrimary }
        #expect(wakeRequest?.content.categoryIdentifier == HimmerFlowNotificationAction.category)
    }

    @Test("Rolling schedule for two close shifts stays within cap")
    func twoConsecutiveShiftsWithinCap() async throws {
        let settings = defaultSettings()
        let firstClockIn = makeDate(year: 2026, month: 1, day: 5, hour: 23, minute: 0)
        let secondClockIn = makeDate(year: 2026, month: 1, day: 6, hour: 15, minute: 0)
        let now = makeDate(year: 2026, month: 1, day: 5, hour: 18, minute: 0)

        let shifts = [
            NotificationPlanner.ShiftScheduleItem(
                timeline: standardTimeline(clockIn: firstClockIn, settings: settings),
                patternName: "Night"
            ),
            NotificationPlanner.ShiftScheduleItem(
                timeline: standardTimeline(clockIn: secondClockIn, settings: settings),
                patternName: "Afternoon"
            ),
        ]

        let requests = NotificationPlanner.rollingRequests(
            shifts: shifts,
            settings: settings,
            calendar: calendar,
            now: now
        )

        #expect(requests.count <= NotificationPlanner.maxPending)
        #expect(NotificationPlanner.shiftsEligibleForRollingSchedule(shifts, calendar: calendar).count == 2)

        let service = MockNotificationService()
        for request in requests {
            try await service.schedule(request)
        }
        #expect(await service.scheduledNotificationCount() <= NotificationPlanner.maxPending)
    }

    @Test("Rolling schedule excludes distant future shifts")
    func rollingScheduleExcludesDistantShifts() {
        let settings = defaultSettings()
        let now = makeDate(year: 2026, month: 1, day: 5, hour: 10, minute: 0)

        let shifts = (0..<5).map { offset in
            let clockIn = calendar.date(byAdding: .day, value: offset, to: makeDate(year: 2026, month: 1, day: 5, hour: 23, minute: 0))!
            return NotificationPlanner.ShiftScheduleItem(
                timeline: standardTimeline(clockIn: clockIn, settings: settings),
                patternName: "Shift \(offset)"
            )
        }

        let eligible = NotificationPlanner.shiftsEligibleForRollingSchedule(shifts, calendar: calendar)
        #expect(eligible.count == 1)

        let requests = NotificationPlanner.rollingRequests(
            shifts: shifts,
            settings: settings,
            calendar: calendar,
            now: now
        )
        #expect(requests.count <= NotificationPlanner.maxPending)
    }

    @Test("Cancel by shift date prefix removes only that shift")
    func cancelByShiftPrefix() async throws {
        let settings = defaultSettings()
        let firstClockIn = makeDate(year: 2026, month: 1, day: 5, hour: 23, minute: 0)
        let secondClockIn = makeDate(year: 2026, month: 1, day: 7, hour: 23, minute: 0)

        let service = MockNotificationService()
        let firstRequests = NotificationPlanner.requests(
            for: standardTimeline(clockIn: firstClockIn, settings: settings),
            settings: settings,
            patternName: "A",
            calendar: calendar
        )
        let secondRequests = NotificationPlanner.requests(
            for: standardTimeline(clockIn: secondClockIn, settings: settings),
            settings: settings,
            patternName: "B",
            calendar: calendar
        )

        for request in firstRequests + secondRequests {
            try await service.schedule(request)
        }

        let matchesFirst = NotificationPlanner.identifiers(withShiftPrefix: firstClockIn, calendar: calendar)
        let firstIDs = await service.pendingIdentifiers().filter(matchesFirst)
        await service.cancel(identifiers: firstIDs)

        let remaining = await service.pendingIdentifiers()
        #expect(remaining.allSatisfy { !matchesFirst($0) })
        #expect(remaining.count == secondRequests.count)
        #expect(service.cancelledIDs == firstIDs)
    }

    @Test("Snooze schedules notification five minutes later")
    func snoozeAddsFiveMinuteReminder() async throws {
        let settings = defaultSettings()
        let clockIn = makeDate(year: 2026, month: 1, day: 5, hour: 23, minute: 0)
        let now = makeDate(year: 2026, month: 1, day: 5, hour: 21, minute: 30)

        let snoozeRequest = NotificationPlanner.snoozeRequest(
            phase: .wake,
            shiftDate: clockIn,
            title: "Time to get up",
            body: "Shift at 11:00 PM. Get moving.",
            now: now,
            calendar: calendar
        )

        let service = MockNotificationService()
        try await service.schedule(snoozeRequest)

        let expectedFire = calendar.date(byAdding: .minute, value: NotificationPlanner.snoozeDelayMinutes, to: now)!
        let actualFire = fireDate(for: snoozeRequest)
        #expect(actualFire == expectedFire)
        #expect(snoozeRequest.identifier.contains("snooze"))
        #expect(await service.scheduledNotificationCount() == 1)
    }
}
