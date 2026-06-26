import Foundation
import UserNotifications

public protocol NotificationServiceProtocol: Sendable {
    func scheduledNotificationCount() async -> Int
    func schedule(_ request: UNNotificationRequest) async throws
    func cancel(identifiers: [String]) async
    func cancelAll() async
    func pendingIdentifiers() async -> [String]
    func registerCategories() async
}

public enum HimmerFlowNotificationID {
    public static func make(
        shiftDate: Date,
        phase: ShiftTimelinePhase,
        isPrimary: Bool,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let token = HimmerFlowDateFormatting.shiftDateToken(shiftDate, calendar: calendar)
        return "himmerflow.\(token).\(phase.rawValue).\(isPrimary ? "primary" : "backup")"
    }

    public static func shiftPrefix(shiftDate: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        "himmerflow.\(HimmerFlowDateFormatting.shiftDateToken(shiftDate, calendar: calendar))"
    }

    public static func snooze(
        shiftDate: Date,
        phase: ShiftTimelinePhase,
        firedAt: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let token = HimmerFlowDateFormatting.shiftDateToken(shiftDate, calendar: calendar)
        return "himmerflow.\(token).\(phase.rawValue).snooze.\(Int(firedAt.timeIntervalSince1970))"
    }
}

public enum HimmerFlowNotificationAction {
    public static let ack = "ACK"
    public static let snooze = "SNOOZE"
    public static let category = "PHASE_ACK"
}
