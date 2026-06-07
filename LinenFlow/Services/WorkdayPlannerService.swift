import Foundation

enum WorkdayPlannerService {
    // 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    static let defaultWorkdays: Set<Int> = [1, 2, 5, 6, 7]

    static func buildDefaultSchedule() -> [WorkScheduleDay] {
        (1...7).map { weekday in
            WorkScheduleDay(
                weekday: weekday,
                isWorkday: defaultWorkdays.contains(weekday)
            )
        }
    }

    static func calculateStartDrivingTime(targetArrivalTime: Date, driveMinutes: Int) -> Date {
        targetArrivalTime.addingTimeInterval(-Double(driveMinutes) * 60)
    }

    static func calculateWalkToCarTime(startDrivingTime: Date, walkToCarMinutes: Int) -> Date {
        startDrivingTime.addingTimeInterval(-Double(walkToCarMinutes) * 60)
    }

    static func calculateBufferStartTime(walkToCarTime: Date, safetyBufferMinutes: Int) -> Date {
        walkToCarTime.addingTimeInterval(-Double(safetyBufferMinutes) * 60)
    }

    static func calculateStartGettingReadyTime(bufferStartTime: Date, prepMinutes: Int) -> Date {
        bufferStartTime.addingTimeInterval(-Double(prepMinutes) * 60)
    }

    static func calculateLeaveSoonTime(walkToCarTime: Date, leaveSoonAlertMinutes: Int) -> Date {
        walkToCarTime.addingTimeInterval(-Double(leaveSoonAlertMinutes) * 60)
    }

    static func calculateShiftSoonTime(shiftStartTime: Date, shiftSoonAlertMinutes: Int) -> Date {
        shiftStartTime.addingTimeInterval(-Double(shiftSoonAlertMinutes) * 60)
    }

    static func calculateChecklistReminderTime(walkToCarTime: Date, checklistReminderBeforeMinutes: Int) -> Date {
        walkToCarTime.addingTimeInterval(-Double(checklistReminderBeforeMinutes) * 60)
    }

    static func buildWorkdayPlan(
        weekday: Int,
        shiftStartDate: Date,
        scheduleDay: WorkScheduleDay,
        commutePlan: CommutePlan
    ) -> WorkdayPlan {
        let calendar = Calendar.current
        var startComps = calendar.dateComponents([.year, .month, .day], from: shiftStartDate)
        startComps.hour = scheduleDay.shiftStartHour
        startComps.minute = scheduleDay.shiftStartMinute
        startComps.second = 0
        let shiftStart = calendar.date(from: startComps) ?? shiftStartDate

        var endComps = calendar.dateComponents([.year, .month, .day], from: shiftStartDate)
        endComps.hour = scheduleDay.shiftEndHour
        endComps.minute = scheduleDay.shiftEndMinute
        endComps.second = 0
        var shiftEnd = calendar.date(from: endComps) ?? shiftStartDate
        if scheduleDay.isOvernightShift || shiftEnd <= shiftStart {
            shiftEnd = calendar.date(byAdding: .day, value: 1, to: shiftEnd) ?? shiftEnd
        }

        var arrivalComps = calendar.dateComponents([.year, .month, .day], from: shiftStartDate)
        arrivalComps.hour = commutePlan.targetArrivalHour
        arrivalComps.minute = commutePlan.targetArrivalMinute
        arrivalComps.second = 0
        let targetArrival = calendar.date(from: arrivalComps) ?? shiftStartDate

        let startDriving = calculateStartDrivingTime(targetArrivalTime: targetArrival, driveMinutes: commutePlan.manualEstimatedDriveMinutes)
        let walkToCar = calculateWalkToCarTime(startDrivingTime: startDriving, walkToCarMinutes: commutePlan.walkToCarMinutes)
        let bufferStart = calculateBufferStartTime(walkToCarTime: walkToCar, safetyBufferMinutes: commutePlan.safetyBufferMinutes)
        let getReady = calculateStartGettingReadyTime(bufferStartTime: bufferStart, prepMinutes: commutePlan.prepMinutes)
        let leaveSoon = calculateLeaveSoonTime(walkToCarTime: walkToCar, leaveSoonAlertMinutes: commutePlan.leaveSoonAlertMinutes)
        let checklistReminder = calculateChecklistReminderTime(walkToCarTime: walkToCar, checklistReminderBeforeMinutes: commutePlan.checklistReminderBeforeWalkToCarMinutes)
        let shiftSoon = calculateShiftSoonTime(shiftStartTime: shiftStart, shiftSoonAlertMinutes: commutePlan.shiftSoonAlertMinutes)

        var warnings: [String] = []
        if scheduleDay.assignedTowerName == "Unassigned" {
            warnings.append("No tower assigned for this shift.")
        }

        return WorkdayPlan(
            weekday: weekday,
            shiftStartDateTime: shiftStart,
            shiftEndDateTime: shiftEnd,
            assignedTowerName: scheduleDay.assignedTowerName,
            targetArrivalTime: targetArrival,
            startDrivingTime: startDriving,
            walkToCarTime: walkToCar,
            bufferStartTime: bufferStart,
            startGettingReadyTime: getReady,
            leaveSoonTime: leaveSoon,
            checklistReminderTime: checklistReminder,
            shiftSoonTime: shiftSoon,
            warnings: warnings
        )
    }

    static func nextWorkShift(schedule: [WorkScheduleDay], from referenceDate: Date = .now) -> (WorkScheduleDay, Date)? {
        let calendar = Calendar.current
        for offset in 0...7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: referenceDate) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            guard let day = schedule.first(where: { $0.weekday == weekday && $0.isWorkday }) else { continue }
            return (day, calendar.startOfDay(for: date))
        }
        return nil
    }

    static func isWorkday(_ schedule: [WorkScheduleDay], date: Date = .now) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return schedule.first(where: { $0.weekday == weekday })?.isWorkday ?? false
    }

    static func validateSchedule(_ schedule: [WorkScheduleDay]) -> [String] {
        var warnings: [String] = []
        let workdays = schedule.filter(\.isWorkday)
        if workdays.isEmpty {
            warnings.append("No work days scheduled.")
        }
        let unassigned = workdays.filter { $0.assignedTowerName == "Unassigned" }
        if !unassigned.isEmpty {
            let names = unassigned.map(\.weekdayName).joined(separator: ", ")
            warnings.append("Tower not assigned for: \(names)")
        }
        return warnings
    }
}
