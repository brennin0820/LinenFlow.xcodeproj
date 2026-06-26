import Foundation

public struct WorkShiftWindow {
    public let start: Date
    public let end: Date

    public static func containing(
        _ date: Date,
        startHour: Int = 23,
        startMinute: Int = 0,
        endHour: Int = 19,
        endMinute: Int = 0,
        calendar: Calendar = .current
    ) -> WorkShiftWindow {
        let dayStart = calendar.startOfDay(for: date)
        let startToday = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: dayStart) ?? date
        var endToday = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: dayStart) ?? date
        if endToday <= startToday {
            endToday = calendar.date(byAdding: .day, value: 1, to: endToday) ?? endToday
        }

        if date >= startToday {
            return WorkShiftWindow(start: startToday, end: endToday)
        }

        let previousDay = calendar.date(byAdding: .day, value: -1, to: dayStart) ?? dayStart
        let previousStart = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: previousDay) ?? date
        var previousEnd = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: previousDay) ?? date
        if previousEnd <= previousStart {
            previousEnd = calendar.date(byAdding: .day, value: 1, to: previousEnd) ?? previousEnd
        }

        if date <= previousEnd {
            return WorkShiftWindow(start: previousStart, end: previousEnd)
        }

        return WorkShiftWindow(start: startToday, end: endToday)
    }
}
