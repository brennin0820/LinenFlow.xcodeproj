import Testing
import Foundation
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

// MARK: - Helper

private func makeTime(hour: Int, minute: Int) -> Date {
    var comps = DateComponents()
    comps.year = 2026
    comps.month = 1
    comps.day = 5
    comps.hour = hour
    comps.minute = minute
    comps.second = 0
    return Calendar.current.date(from: comps)!
}

// MARK: - WorkdayPlannerService Tests

@Suite("WorkdayPlannerService")
struct WorkdayPlannerServiceTests {

    @Test("Default schedule has correct work days (Sun, Mon, Thu, Fri, Sat)")
    func defaultScheduleWorkdays() {
        let schedule = WorkdayPlannerService.buildDefaultSchedule()
        let workdays = Set(schedule.filter(\.isWorkday).map(\.weekday))
        #expect(workdays == Set([1, 2, 5, 6, 7]))
    }

    @Test("Default schedule has correct off days (Tue, Wed)")
    func defaultScheduleOffdays() {
        let schedule = WorkdayPlannerService.buildDefaultSchedule()
        let offdays = Set(schedule.filter { !$0.isWorkday }.map(\.weekday))
        #expect(offdays == Set([3, 4]))
    }

    @Test("Default target arrival calculation produces correct times")
    func defaultTargetArrivalCalculation() {
        let target = makeTime(hour: 22, minute: 45)

        let startDriving = WorkdayPlannerService.calculateStartDrivingTime(targetArrivalTime: target, driveMinutes: 30)
        #expect(startDriving == makeTime(hour: 22, minute: 15))

        let walkToCar = WorkdayPlannerService.calculateWalkToCarTime(startDrivingTime: startDriving, walkToCarMinutes: 5)
        #expect(walkToCar == makeTime(hour: 22, minute: 10))

        let bufferStart = WorkdayPlannerService.calculateBufferStartTime(walkToCarTime: walkToCar, safetyBufferMinutes: 15)
        #expect(bufferStart == makeTime(hour: 21, minute: 55))

        let getReady = WorkdayPlannerService.calculateStartGettingReadyTime(bufferStartTime: bufferStart, prepMinutes: 40)
        #expect(getReady == makeTime(hour: 21, minute: 15))

        let leaveSoon = WorkdayPlannerService.calculateLeaveSoonTime(walkToCarTime: walkToCar, leaveSoonAlertMinutes: 10)
        #expect(leaveSoon == makeTime(hour: 22, minute: 0))

        let checklistReminder = WorkdayPlannerService.calculateChecklistReminderTime(walkToCarTime: walkToCar, checklistReminderBeforeMinutes: 5)
        #expect(checklistReminder == makeTime(hour: 22, minute: 5))

        let shiftStart = makeTime(hour: 23, minute: 0)
        let shiftSoon = WorkdayPlannerService.calculateShiftSoonTime(shiftStartTime: shiftStart, shiftSoonAlertMinutes: 10)
        #expect(shiftSoon == makeTime(hour: 22, minute: 50))
    }

    @Test("Overnight shift end is next calendar day")
    func overnightShiftEndIsNextDay() throws {
        let schedule = WorkdayPlannerService.buildDefaultSchedule()
        let mondaySchedule = try #require(schedule.first(where: { $0.weekday == 2 }))

        var startComps = DateComponents()
        startComps.year = 2026; startComps.month = 1; startComps.day = 5
        startComps.hour = 23; startComps.minute = 0
        let shiftStartDate = try #require(Calendar.current.date(from: startComps))

        let plan = WorkdayPlannerService.buildWorkdayPlan(
            weekday: 2,
            shiftStartDate: shiftStartDate,
            scheduleDay: mondaySchedule,
            commutePlan: CommutePlan()
        )

        let cal = Calendar.current
        let startDay = cal.startOfDay(for: plan.shiftStartDateTime)
        let endDay = cal.startOfDay(for: plan.shiftEndDateTime)
        let dayDiff = cal.dateComponents([.day], from: startDay, to: endDay)
        #expect(dayDiff.day == 1)
        #expect(plan.weekday == 2)
    }

    @Test("Tower assignment for Thursday persists correctly")
    func towerAssignmentThursday() {
        var schedule = WorkdayPlannerService.buildDefaultSchedule()
        if let idx = schedule.firstIndex(where: { $0.weekday == 5 }) {
            schedule[idx].assignedTowerName = "Tapa"
        }
        let thursday = schedule.first(where: { $0.weekday == 5 })!
        #expect(thursday.assignedTowerName == "Tapa")
    }

    @Test("All default workdays have Unassigned tower")
    func defaultTowerIsUnassigned() {
        let schedule = WorkdayPlannerService.buildDefaultSchedule()
        let workdays = schedule.filter(\.isWorkday)
        #expect(workdays.allSatisfy { $0.assignedTowerName == "Unassigned" })
    }

    @Test("Zero drive time does not crash and equals target arrival")
    func zeroDriveTimeNoCrash() {
        let target = makeTime(hour: 22, minute: 45)
        let result = WorkdayPlannerService.calculateStartDrivingTime(targetArrivalTime: target, driveMinutes: 0)
        #expect(result == target)
    }

    @Test("Zero prep time does not crash and equals buffer start")
    func zeroPrepTimeNoCrash() {
        let bufferStart = makeTime(hour: 21, minute: 55)
        let result = WorkdayPlannerService.calculateStartGettingReadyTime(bufferStartTime: bufferStart, prepMinutes: 0)
        #expect(result == bufferStart)
    }

    @Test("Zero walk-to-car time does not crash and equals start driving")
    func zeroWalkToCarNoCrash() {
        let startDriving = makeTime(hour: 22, minute: 15)
        let result = WorkdayPlannerService.calculateWalkToCarTime(startDrivingTime: startDriving, walkToCarMinutes: 0)
        #expect(result == startDriving)
    }

    @Test("Changing walk-to-car minutes updates downstream calculated times")
    func changingWalkToCarUpdatesCalcs() {
        let target = makeTime(hour: 22, minute: 45)
        let startDriving = WorkdayPlannerService.calculateStartDrivingTime(targetArrivalTime: target, driveMinutes: 30)

        let walkToCar7 = WorkdayPlannerService.calculateWalkToCarTime(startDrivingTime: startDriving, walkToCarMinutes: 7)
        let walkToCar5 = WorkdayPlannerService.calculateWalkToCarTime(startDrivingTime: startDriving, walkToCarMinutes: 5)
        #expect(walkToCar7 != walkToCar5)

        let leaveSoon7 = WorkdayPlannerService.calculateLeaveSoonTime(walkToCarTime: walkToCar7, leaveSoonAlertMinutes: 10)
        let leaveSoon5 = WorkdayPlannerService.calculateLeaveSoonTime(walkToCarTime: walkToCar5, leaveSoonAlertMinutes: 10)
        #expect(leaveSoon7 != leaveSoon5)

        let getReady7 = WorkdayPlannerService.calculateStartGettingReadyTime(
            bufferStartTime: WorkdayPlannerService.calculateBufferStartTime(walkToCarTime: walkToCar7, safetyBufferMinutes: 15),
            prepMinutes: 40
        )
        let getReady5 = WorkdayPlannerService.calculateStartGettingReadyTime(
            bufferStartTime: WorkdayPlannerService.calculateBufferStartTime(walkToCarTime: walkToCar5, safetyBufferMinutes: 15),
            prepMinutes: 40
        )
        #expect(getReady7 != getReady5)

        let checklist7 = WorkdayPlannerService.calculateChecklistReminderTime(walkToCarTime: walkToCar7, checklistReminderBeforeMinutes: 5)
        let checklist5 = WorkdayPlannerService.calculateChecklistReminderTime(walkToCarTime: walkToCar5, checklistReminderBeforeMinutes: 5)
        #expect(checklist7 != checklist5)
    }

    @Test("Tuesday is an off day — no tower required")
    func tuesdayIsOffDay() {
        let schedule = WorkdayPlannerService.buildDefaultSchedule()
        let tuesday = schedule.first(where: { $0.weekday == 3 })!
        #expect(!tuesday.isWorkday)
    }
}

// MARK: - WazeRouteService Tests

@Suite("WazeRouteService")
struct WazeRouteServiceTests {

    @Test("Search address URL contains encoded query and navigate=yes")
    func wazeSearchAddressURL() throws {
        let url = try #require(WazeRouteService.buildURL(mode: .searchAddress("2005 Kalia Rd, Honolulu, HI")))
        let str = url.absoluteString
        #expect(str.contains("navigate=yes"))
        #expect(str.contains("2005") || str.contains("Kalia") || str.contains("q="))
    }

    @Test("Waze favorite work URL is exact")
    func wazeFavoriteWorkURL() throws {
        let url = try #require(WazeRouteService.buildURL(mode: .favWork))
        #expect(url.absoluteString == "https://waze.com/ul?favorite=work&navigate=yes")
    }

    @Test("Waze coordinate URL contains ll parameter and navigate=yes")
    func wazeCoordinateURL() throws {
        let url = try #require(WazeRouteService.buildURL(mode: .coordinates(lat: 21.2830, lon: -157.8360)))
        let str = url.absoluteString
        #expect(str.contains("21.283"))
        #expect(str.contains("157.836"))
        #expect(str.contains("navigate=yes"))
    }
}

// MARK: - LeavingChecklistService Tests

@Suite("LeavingChecklistService")
struct LeavingChecklistServiceTests {

    @Test("Default items are AirPods, Charger, Vape")
    func defaultChecklistItems() {
        let items = LeavingChecklistService.buildDefaultItems()
        let titles = items.map(\.title)
        #expect(titles.contains("AirPods"))
        #expect(titles.contains("Charger"))
        #expect(titles.contains("Vape"))
        #expect(items.count == 3)
    }

    @Test("Notification body for 3 default items is correctly formatted")
    func checklistNotificationBodyThreeItems() {
        let items = LeavingChecklistService.buildDefaultItems()
        let body = LeavingChecklistService.buildNotificationBody(from: items)
        #expect(body == "Check airpods, charger, and vape before leaving.")
    }

    @Test("Notification body with 5 items uses generic fallback message")
    func checklistNotificationBodyManyItems() {
        var items = LeavingChecklistService.buildDefaultItems()
        items.append(LeavingChecklistItem(title: "Keys", isEnabled: true, sortOrder: 3))
        items.append(LeavingChecklistItem(title: "Wallet", isEnabled: true, sortOrder: 4))
        let body = LeavingChecklistService.buildNotificationBody(from: items)
        #expect(body == "Check your leaving checklist before heading out.")
    }

    @Test("Checklist reminder time is 5 minutes before walk-to-car")
    func checklistReminderTime() {
        let walkToCarTime = makeTime(hour: 22, minute: 10)
        let reminderTime = LeavingChecklistService.calculateChecklistReminderTime(walkToCarTime: walkToCarTime, remindBeforeMinutes: 5)
        #expect(reminderTime == makeTime(hour: 22, minute: 5))
    }

    @Test("Zero checklist reminder offset equals walk-to-car time")
    func zeroChecklistReminderOffset() {
        let walkToCarTime = makeTime(hour: 22, minute: 10)
        let reminderTime = LeavingChecklistService.calculateChecklistReminderTime(walkToCarTime: walkToCarTime, remindBeforeMinutes: 0)
        #expect(reminderTime == walkToCarTime)
    }

    @Test("Disabled item is excluded from notification body")
    func disabledItemExcludedFromBody() {
        var items = LeavingChecklistService.buildDefaultItems()
        if let idx = items.firstIndex(where: { $0.title == "Charger" }) {
            items[idx].isEnabled = false
        }
        let body = LeavingChecklistService.buildNotificationBody(from: items)
        #expect(!body.lowercased().contains("charger"))
        #expect(body.lowercased().contains("airpods"))
        #expect(body.lowercased().contains("vape"))
    }

    @Test("shouldResetCheckedItems returns true when last reset was yesterday")
    func checkedItemsResetYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let shouldReset = LeavingChecklistService.shouldResetCheckedItems(lastResetDate: yesterday)
        #expect(shouldReset)
    }

    @Test("shouldResetCheckedItems returns false when last reset was today")
    func checkedItemsNotResetToday() {
        let shouldReset = LeavingChecklistService.shouldResetCheckedItems(lastResetDate: .now)
        #expect(!shouldReset)
    }

    @Test("shouldResetCheckedItems returns true when lastResetDate is nil")
    func checkedItemsResetWhenNil() {
        let shouldReset = LeavingChecklistService.shouldResetCheckedItems(lastResetDate: nil)
        #expect(shouldReset)
    }

    @Test("App works correctly without Wi-Fi detection — time-based notifications function independently")
    func appWorksWithoutWifiDetection() {
        let items = LeavingChecklistService.buildDefaultItems()
        let walkToCarTime = makeTime(hour: 22, minute: 10)
        let reminderTime = LeavingChecklistService.calculateChecklistReminderTime(walkToCarTime: walkToCarTime, remindBeforeMinutes: 5)
        #expect(reminderTime < walkToCarTime)
        let body = LeavingChecklistService.buildNotificationBody(from: items)
        #expect(!body.isEmpty)
    }

    @Test("Notification identifier prefix is stable")
    func notificationIdentifierPrefix() {
        let prefix = ShiftAlarmNotificationService.identifierPrefix
        #expect(prefix == "himmerflow.shift.alarm")
    }
}
