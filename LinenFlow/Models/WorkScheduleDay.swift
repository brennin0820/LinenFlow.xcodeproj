import Foundation

struct WorkScheduleDay: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var weekday: Int  // 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    var isWorkday: Bool
    var shiftStartHour: Int = 23
    var shiftStartMinute: Int = 0
    var shiftEndHour: Int = 7
    var shiftEndMinute: Int = 0
    var isOvernightShift: Bool = true
    var assignedTowerName: String = "Unassigned"
    var customTowerName: String? = nil
    var notes: String = ""

    var weekdayName: String {
        Calendar.current.weekdaySymbols[weekday - 1]
    }

    var shortWeekdayName: String {
        Calendar.current.shortWeekdaySymbols[weekday - 1]
    }

    var veryShortWeekdayName: String {
        Calendar.current.veryShortWeekdaySymbols[weekday - 1]
    }

    var shiftTimeLabel: String {
        let startH = shiftStartHour % 12 == 0 ? 12 : shiftStartHour % 12
        let startM = String(format: "%02d", shiftStartMinute)
        let startPeriod = shiftStartHour < 12 ? "AM" : "PM"
        let endH = shiftEndHour % 12 == 0 ? 12 : shiftEndHour % 12
        let endM = String(format: "%02d", shiftEndMinute)
        let endPeriod = shiftEndHour < 12 ? "AM" : "PM"
        return "\(startH):\(startM) \(startPeriod) – \(endH):\(endM) \(endPeriod)"
    }
}
