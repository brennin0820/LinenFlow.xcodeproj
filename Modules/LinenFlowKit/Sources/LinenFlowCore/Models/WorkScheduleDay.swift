import Foundation

public struct WorkScheduleDay: Codable, Identifiable, Hashable {
    public var id: UUID = UUID()
    public var weekday: Int  // 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    public var isWorkday: Bool
    public var shiftStartHour: Int = 23
    public var shiftStartMinute: Int = 0
    public var shiftEndHour: Int = 7
    public var shiftEndMinute: Int = 0
    public var isOvernightShift: Bool = true
    public var assignedTowerName: String = "Unassigned"
    public var customTowerName: String? = nil
    public var notes: String = ""

    public var weekdayName: String {
        Calendar.current.weekdaySymbols[weekday - 1]
    }

    public var shortWeekdayName: String {
        Calendar.current.shortWeekdaySymbols[weekday - 1]
    }

    public var veryShortWeekdayName: String {
        Calendar.current.veryShortWeekdaySymbols[weekday - 1]
    }

    public var shiftTimeLabel: String {
        let startH = shiftStartHour % 12 == 0 ? 12 : shiftStartHour % 12
        let startM = String(format: "%02d", shiftStartMinute)
        let startPeriod = shiftStartHour < 12 ? "AM" : "PM"
        let endH = shiftEndHour % 12 == 0 ? 12 : shiftEndHour % 12
        let endM = String(format: "%02d", shiftEndMinute)
        let endPeriod = shiftEndHour < 12 ? "AM" : "PM"
        return "\(startH):\(startM) \(startPeriod) – \(endH):\(endM) \(endPeriod)"
    }
}
