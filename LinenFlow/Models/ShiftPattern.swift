import Foundation
import SwiftData

@Model
final class ShiftPattern {
    var id: UUID
    var name: String
    var weekdayRawValues: [Int]
    var clockInHour: Int
    var clockInMinute: Int
    var shiftDurationMinutes: Int
    var isActive: Bool
    @Relationship(deleteRule: .nullify) var workLocation: SavedLocation?

    var daysOfWeek: Set<Weekday> {
        get { Set(weekdayRawValues.compactMap(Weekday.init(rawValue:))) }
        set { weekdayRawValues = newValue.map(\.rawValue).sorted() }
    }

    var clockInTime: DateComponents {
        get { DateComponents(hour: clockInHour, minute: clockInMinute) }
        set {
            clockInHour = newValue.hour ?? 0
            clockInMinute = newValue.minute ?? 0
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        daysOfWeek: Set<Weekday> = [],
        clockInTime: DateComponents = DateComponents(hour: 23, minute: 0),
        shiftDurationMinutes: Int = 480,
        workLocation: SavedLocation? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.weekdayRawValues = daysOfWeek.map(\.rawValue).sorted()
        self.clockInHour = clockInTime.hour ?? 0
        self.clockInMinute = clockInTime.minute ?? 0
        self.shiftDurationMinutes = shiftDurationMinutes
        self.workLocation = workLocation
        self.isActive = isActive
    }

    func nextOccurrence(after referenceDate: Date, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        guard isActive, !daysOfWeek.isEmpty else { return nil }

        for dayOffset in 0..<14 {
            guard let candidateDay = calendar.date(byAdding: .day, value: dayOffset, to: referenceDate) else { continue }
            let weekday = calendar.component(.weekday, from: candidateDay)
            guard let match = Weekday(rawValue: weekday), daysOfWeek.contains(match) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: candidateDay)
            components.hour = clockInHour
            components.minute = clockInMinute
            components.second = 0
            guard let occurrence = calendar.date(from: components) else { continue }

            if occurrence > referenceDate {
                return occurrence
            }
        }
        return nil
    }
}
