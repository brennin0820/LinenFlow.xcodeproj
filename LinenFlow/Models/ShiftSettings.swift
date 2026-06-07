import Foundation
import Observation

@Observable
final class ShiftSettings {
    var targetHour: Int {
        didSet { UserDefaults.standard.set(targetHour, forKey: "shift.targetHour") }
    }
    var targetMinute: Int {
        didSet { UserDefaults.standard.set(targetMinute, forKey: "shift.targetMinute") }
    }
    var shiftStartHour: Int {
        didSet { UserDefaults.standard.set(shiftStartHour, forKey: "shift.startHour") }
    }
    var shiftStartMinute: Int {
        didSet { UserDefaults.standard.set(shiftStartMinute, forKey: "shift.startMinute") }
    }
    var shiftEndHour: Int {
        didSet { UserDefaults.standard.set(shiftEndHour, forKey: "shift.endHour") }
    }
    var shiftEndMinute: Int {
        didSet { UserDefaults.standard.set(shiftEndMinute, forKey: "shift.endMinute") }
    }

    init() {
        let ud = UserDefaults.standard
        targetHour   = ud.object(forKey: "shift.targetHour")   as? Int ?? 6
        targetMinute = ud.object(forKey: "shift.targetMinute") as? Int ?? 45
        shiftStartHour = ud.object(forKey: "shift.startHour") as? Int ?? 23
        shiftStartMinute = ud.object(forKey: "shift.startMinute") as? Int ?? 0
        shiftEndHour   = ud.object(forKey: "shift.endHour")   as? Int ?? 7
        shiftEndMinute = ud.object(forKey: "shift.endMinute") as? Int ?? 0
    }

    var targetTime: Date {
        targetTime(for: .now)
    }

    func targetTime(for referenceDate: Date, calendar: Calendar = .current) -> Date {
        let shiftWindow = WorkShiftWindow.containing(
            referenceDate,
            startHour: shiftStartHour,
            startMinute: shiftStartMinute,
            endHour: shiftEndHour,
            endMinute: shiftEndMinute,
            calendar: calendar
        )

        var components = calendar.dateComponents([.year, .month, .day], from: shiftWindow.start)
        components.hour = targetHour
        components.minute = targetMinute
        components.second = 0

        var candidate = calendar.date(from: components) ?? referenceDate
        while candidate < shiftWindow.start {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }

    func widgetTargetTime(referenceDate: Date = .now) -> Date {
        targetTime(for: referenceDate)
    }
}
