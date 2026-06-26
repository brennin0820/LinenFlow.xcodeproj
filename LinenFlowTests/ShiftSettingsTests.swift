import XCTest
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class ShiftSettingsTests: XCTestCase {

    func test_defaults_targetHour6_targetMinute45() {
        // Clear any stored values so we get defaults
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "shift.targetHour")
        ud.removeObject(forKey: "shift.targetMinute")
        ud.removeObject(forKey: "shift.startHour")
        ud.removeObject(forKey: "shift.startMinute")
        ud.removeObject(forKey: "shift.endHour")
        ud.removeObject(forKey: "shift.endMinute")

        let settings = ShiftSettings()

        XCTAssertEqual(settings.targetHour, 6, "Default target hour should be 6 AM")
        XCTAssertEqual(settings.targetMinute, 45, "Default target minute should be 45")
        XCTAssertEqual(settings.shiftStartHour, 23, "Default shift start should be 11 PM")
        XCTAssertEqual(settings.shiftStartMinute, 0, "Default shift start minute should be 0")
        XCTAssertEqual(settings.shiftEndHour, 7, "Default shift end should be 7 AM")
        XCTAssertEqual(settings.shiftEndMinute, 0, "Default shift end minute should be 0")
    }

    func test_targetTime_returnsNonNilDate() {
        let settings = ShiftSettings()
        let target = settings.targetTime
        XCTAssertNotNil(target)
    }

    func test_targetTime_doesNotRollToTomorrowWhenCurrentShiftTargetIsOverdue() throws {
        let settings = ShiftSettings()
        settings.shiftStartHour = 23
        settings.shiftStartMinute = 0
        settings.shiftEndHour = 7
        settings.shiftEndMinute = 0
        settings.targetHour = 6
        settings.targetMinute = 45

        let calendar = Calendar(identifier: .gregorian)
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 2,
            hour: 6,
            minute: 50
        )))

        let target = settings.targetTime(for: reference, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: target), 2)
        XCTAssertEqual(calendar.component(.hour, from: target), 6)
        XCTAssertEqual(calendar.component(.minute, from: target), 45)
        XCTAssertLessThan(target, reference)
    }

    func test_targetTime_usesNextMorningForOvernightShiftBeforeTarget() throws {
        let settings = ShiftSettings()
        settings.shiftStartHour = 23
        settings.shiftStartMinute = 0
        settings.shiftEndHour = 7
        settings.shiftEndMinute = 0
        settings.targetHour = 6
        settings.targetMinute = 45

        let calendar = Calendar(identifier: .gregorian)
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 1,
            hour: 23,
            minute: 30
        )))

        let target = settings.targetTime(for: reference, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: target), 2)
        XCTAssertEqual(calendar.component(.hour, from: target), 6)
        XCTAssertEqual(calendar.component(.minute, from: target), 45)
        XCTAssertGreaterThan(target, reference)
    }
}
