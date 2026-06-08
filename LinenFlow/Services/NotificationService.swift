import Foundation
import OSLog
import UserNotifications

final class NotificationService: NotificationServiceProtocol, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func scheduledNotificationCount() async -> Int {
        await center.pendingNotificationRequests().count
    }

    func schedule(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
        let fireDate = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()?.description ?? "unknown"
        HimmerFlowLog.notifications.info("Notification scheduled: \(request.identifier, privacy: .public), fireDate: \(fireDate, privacy: .public)")
    }

    func cancel(identifiers: [String]) async {
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        for id in identifiers {
            HimmerFlowLog.notifications.info("Notification cancelled: \(id, privacy: .public), reason: reconcile")
        }
    }

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
        HimmerFlowLog.notifications.info("Notification cancelled: all, reason: settingsChanged")
    }

    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    func registerCategories() async {
        let ackAction = UNNotificationAction(
            identifier: HimmerFlowNotificationAction.ack,
            title: "I'm on it",
            options: .foreground
        )
        let snoozeAction = UNNotificationAction(
            identifier: HimmerFlowNotificationAction.snooze,
            title: "5 more min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: HimmerFlowNotificationAction.category,
            actions: [ackAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    static func makeRequest(
        identifier: String,
        title: String,
        body: String,
        fireDate: Date,
        calendar: Calendar,
        requiresAck: Bool
    ) -> UNNotificationRequest {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if requiresAck {
            content.categoryIdentifier = HimmerFlowNotificationAction.category
        }
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}

enum NotificationPlanner {
    static let maxPending = 64
    static let backupDelayMinutes = 10
    static let snoozeDelayMinutes = 5
    static let rollingSecondShiftWindowHours = 12

    struct ShiftScheduleItem: Sendable {
        let timeline: ShiftTimelineSnapshot
        let patternName: String
    }

    static func requests(
        for timeline: ShiftTimelineSnapshot,
        settings: ShiftPlannerSettings,
        patternName: String,
        calendar: Calendar
    ) -> [UNNotificationRequest] {
        var requests: [UNNotificationRequest] = []
        let anchor = timeline.primaryAnchor
        let clockInLabel = HimmerFlowDateFormatting.timeString(anchor, calendar: calendar)

        func append(_ phase: ShiftTimelinePhase, title: String, body: String, at date: Date, requiresAck: Bool) {
            let primaryID = HimmerFlowNotificationID.make(shiftDate: anchor, phase: phase, isPrimary: true, calendar: calendar)
            requests.append(NotificationService.makeRequest(
                identifier: primaryID,
                title: title,
                body: body,
                fireDate: date,
                calendar: calendar,
                requiresAck: requiresAck
            ))
            if requiresAck {
                let backupDate = calendar.date(byAdding: DateComponents(minute: backupDelayMinutes), to: date)!
                let backupID = HimmerFlowNotificationID.make(shiftDate: anchor, phase: phase, isPrimary: false, calendar: calendar)
                requests.append(NotificationService.makeRequest(
                    identifier: backupID,
                    title: phase == .leave ? "Still home?" : "Are you up?",
                    body: phase == .leave
                        ? "You should have left \(backupDelayMinutes) min ago. Shift at \(clockInLabel)."
                        : "Are you up? Your shift starts at \(clockInLabel).",
                    fireDate: backupDate,
                    calendar: calendar,
                    requiresAck: false
                ))
            }
        }

        if let preSleep = timeline.window(for: .preSleep) {
            let hours = HimmerFlowDateFormatting.relativeHours(until: anchor, from: preSleep.start)
            append(.preSleep, title: "Time to wind down", body: "Shift in \(hours). Start your bedtime routine.", at: preSleep.start, requiresAck: false)
        }
        if let sleep = timeline.window(for: .sleep) {
            let sleepHours = settings.sleepDurationMinutes / 60
            append(.sleep, title: "Lights out", body: "Get \(sleepHours)h of sleep before your shift.", at: sleep.start, requiresAck: false)
        }
        if let wake = timeline.window(for: .wake) {
            append(.wake, title: "Time to get up", body: "Shift at \(clockInLabel). Get moving.", at: wake.start, requiresAck: true)
        }
        if let getReady = timeline.window(for: .getReady) {
            append(.getReady, title: "Get ready", body: "You have \(settings.getReadyDurationMinutes) minutes before you need to head out.", at: getReady.start, requiresAck: false)
        }
        if let leave = timeline.window(for: .leave) {
            append(.leave, title: "Leave now", body: "Drive time: \(settings.commuteDurationMinutes) min. Clock in by \(clockInLabel).", at: leave.start, requiresAck: true)
        }
        if let countdown = timeline.window(for: .shiftCountdown) {
            append(.shiftCountdown, title: "Almost time", body: "Clock in at \(clockInLabel). 5 minutes.", at: countdown.start, requiresAck: false)
        }
        if let beDown = timeline.window(for: .beDown) {
            append(.beDown, title: "Wind down", body: "Shift ended. Start your bedtime routine for tomorrow.", at: beDown.start, requiresAck: false)
        }

        return Array(requests.prefix(maxPending))
    }

    /// Rolling schedule: next upcoming shift, plus a second only if it starts within 12h of the first ending.
    static func rollingRequests(
        shifts: [ShiftScheduleItem],
        settings: ShiftPlannerSettings,
        calendar: Calendar,
        now: Date
    ) -> [UNNotificationRequest] {
        let upcoming = shifts
            .filter { $0.timeline.primaryAnchor > now }
            .sorted { $0.timeline.primaryAnchor < $1.timeline.primaryAnchor }

        let selected = shiftsEligibleForRollingSchedule(upcoming, calendar: calendar)
        var allRequests: [UNNotificationRequest] = []
        for item in selected {
            allRequests.append(contentsOf: requests(
                for: item.timeline,
                settings: settings,
                patternName: item.patternName,
                calendar: calendar
            ))
        }
        return Array(allRequests.prefix(maxPending))
    }

    static func shiftsEligibleForRollingSchedule(
        _ upcoming: [ShiftScheduleItem],
        calendar: Calendar
    ) -> [ShiftScheduleItem] {
        guard let first = upcoming.first else { return [] }
        var result = [first]
        guard upcoming.count > 1 else { return result }

        let second = upcoming[1]
        let firstEnd = first.timeline.window(for: .beDown)?.end
            ?? first.timeline.window(for: .shiftEnd)?.end
            ?? first.timeline.primaryAnchor
        let gap = second.timeline.primaryAnchor.timeIntervalSince(firstEnd)
        if gap <= TimeInterval(rollingSecondShiftWindowHours * 3600) {
            result.append(second)
        }
        return result
    }

    static func snoozeRequest(
        phase: ShiftTimelinePhase,
        shiftDate: Date,
        title: String,
        body: String,
        now: Date,
        calendar: Calendar
    ) -> UNNotificationRequest {
        let fireDate = calendar.date(byAdding: DateComponents(minute: snoozeDelayMinutes), to: now)!
        let identifier = HimmerFlowNotificationID.snooze(shiftDate: shiftDate, phase: phase, firedAt: now, calendar: calendar)
        return NotificationService.makeRequest(
            identifier: identifier,
            title: title,
            body: body,
            fireDate: fireDate,
            calendar: calendar,
            requiresAck: phase.requiresAcknowledgement
        )
    }

    static func identifiers(withShiftPrefix shiftDate: Date, calendar: Calendar = .autoupdatingCurrent) -> (String) -> Bool {
        let prefix = HimmerFlowNotificationID.shiftPrefix(shiftDate: shiftDate, calendar: calendar)
        return { $0.hasPrefix(prefix) }
    }
}
