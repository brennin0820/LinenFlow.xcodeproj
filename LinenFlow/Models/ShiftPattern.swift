import Foundation
import SwiftData

@Model
final class ShiftPattern {
    var id: UUID
    var name: String
    private var daysOfWeekRawValues: [Int]
    var clockInTime: DateComponents
    var shiftDurationMinutes: Int
    var workLocation: SavedLocation?
    var isActive: Bool

    var daysOfWeek: Set<Weekday> {
        get {
            Set(daysOfWeekRawValues.compactMap { Weekday(rawValue: $0) })
        }
        set {
            daysOfWeekRawValues = newValue.map(\.rawValue).sorted()
        }
    }

    var clockInHour: Int { clockInTime.hour ?? 0 }
    var clockInMinute: Int { clockInTime.minute ?? 0 }

    init(
        id: UUID = UUID(),
        name: String,
        daysOfWeek: Set<Weekday> = [],
        clockInTime: DateComponents,
        shiftDurationMinutes: Int,
        workLocation: SavedLocation? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.daysOfWeekRawValues = daysOfWeek.map(\.rawValue).sorted()
        self.clockInTime = clockInTime
        self.shiftDurationMinutes = shiftDurationMinutes
        self.workLocation = workLocation
        self.isActive = isActive
    }

    /// Computes the next occurrence of this shift on or after the reference date.
    func nextOccurrence(after referenceDate: Date, calendar: Calendar) -> Date? {
        guard isActive, !daysOfWeek.isEmpty else { return nil }
        guard let hour = clockInTime.hour, let minute = clockInTime.minute else { return nil }

        let startOfReferenceDay = calendar.startOfDay(for: referenceDate)

        for dayOffset in 0 ..< 8 {
            guard let candidateDay = calendar.date(byAdding: .day, value: dayOffset, to: startOfReferenceDay) else {
                continue
            }

            let weekdayValue = calendar.component(.weekday, from: candidateDay)
            guard let weekday = Weekday(rawValue: weekdayValue), daysOfWeek.contains(weekday) else {
                continue
            }

            var components = calendar.dateComponents([.year, .month, .day], from: candidateDay)
            components.hour = hour
            components.minute = minute
            components.second = 0

            guard let occurrence = calendar.date(from: components) else { continue }
            if occurrence >= referenceDate {
                return occurrence
            }
        }

        return nil
    }
}
