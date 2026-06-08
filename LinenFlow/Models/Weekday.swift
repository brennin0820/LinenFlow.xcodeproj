import Foundation

enum Weekday: Int, Codable, CaseIterable, Hashable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var calendarWeekday: Int { rawValue }

    init?(calendarWeekday: Int) {
        self.init(rawValue: calendarWeekday)
    }
}
