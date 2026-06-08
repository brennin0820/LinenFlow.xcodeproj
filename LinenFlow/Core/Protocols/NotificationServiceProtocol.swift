import Foundation
import UserNotifications

protocol NotificationServiceProtocol: Sendable {
    func scheduledNotificationCount() async -> Int
    func schedule(_ request: UNNotificationRequest) async throws
    func cancel(identifiers: [String]) async
    func cancelAll() async
    func pendingIdentifiers() async -> [String]
    func registerCategories() async
}

enum HimmerFlowNotificationID {
    static func make(
        shiftDate: Date,
        phase: ShiftTimelinePhase,
        isPrimary: Bool,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let token = HimmerFlowDateFormatting.shiftDateToken(shiftDate, calendar: calendar)
        return "himmerflow.\(token).\(phase.rawValue).\(isPrimary ? "primary" : "backup")"
    }

    static func shiftPrefix(shiftDate: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        "himmerflow.\(HimmerFlowDateFormatting.shiftDateToken(shiftDate, calendar: calendar))"
    }

    static func snooze(
        shiftDate: Date,
        phase: ShiftTimelinePhase,
        firedAt: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let token = HimmerFlowDateFormatting.shiftDateToken(shiftDate, calendar: calendar)
        return "himmerflow.\(token).\(phase.rawValue).snooze.\(Int(firedAt.timeIntervalSince1970))"
    }
}

enum HimmerFlowNotificationAction {
    static let ack = "ACK"
    static let snooze = "SNOOZE"
    static let category = "PHASE_ACK"
}
