import Foundation

public enum HimmerFlowDateFormatting {
    public static func timeString(_ date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    public static func shiftDateToken(_ date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: date)
    }

    public static func relativeHours(until date: Date, from now: Date) -> String {
        let minutes = max(Int(date.timeIntervalSince(now) / 60), 0)
        if minutes >= 60 {
            let hours = minutes / 60
            let rem = minutes % 60
            if rem == 0 { return "\(hours)h" }
            return "\(hours)h \(rem)m"
        }
        return "\(minutes)m"
    }
}
