import Foundation
import UserNotifications
import LinenFlowCore

public enum ShiftAlarmNotificationService {
    public static let identifierPrefix = "himmerflow.shift.alarm"

    public static func scheduleAlarmNotifications(
        workdayPlan: WorkdayPlan,
        alarmPlan: ShiftAlarmPlan,
        commutePlan: CommutePlan,
        checklistItems: [LeavingChecklistItem]
    ) async -> [String] {
        guard alarmPlan.isEnabled else { return [] }

        let center = UNUserNotificationCenter.current()
        var identifiers: [String] = []

        let arrivalFormatted = workdayPlan.targetArrivalTime.formatted(date: .omitted, time: .shortened)
        let walkFormatted = workdayPlan.walkToCarTime.formatted(date: .omitted, time: .shortened)
        let driveFormatted = workdayPlan.startDrivingTime.formatted(date: .omitted, time: .shortened)

        let alarms: [(enabled: Bool, id: String, date: Date, title: String, body: String)] = [
            (
                alarmPlan.getReadyEnabled,
                "\(identifierPrefix).getReady",
                workdayPlan.startGettingReadyTime,
                "Start getting ready",
                "Target arrival is \(arrivalFormatted). Walk to car by \(walkFormatted)."
            ),
            (
                alarmPlan.leaveSoonEnabled,
                "\(identifierPrefix).leaveSoon",
                workdayPlan.leaveSoonTime,
                "Leave soon",
                "Walk to your car in \(commutePlan.leaveSoonAlertMinutes) minutes."
            ),
            (
                alarmPlan.checklistEnabled,
                "\(identifierPrefix).checklist",
                workdayPlan.checklistReminderTime,
                "Leaving checklist",
                LeavingChecklistService.buildNotificationBody(from: checklistItems)
            ),
            (
                alarmPlan.walkToCarEnabled,
                "\(identifierPrefix).walkToCar",
                workdayPlan.walkToCarTime,
                "Walk to car",
                "Head to your car now. Start driving at \(driveFormatted)."
            ),
            (
                alarmPlan.startDrivingEnabled,
                "\(identifierPrefix).startDriving",
                workdayPlan.startDrivingTime,
                "Start driving",
                "Open Maps and start driving to arrive by \(arrivalFormatted)."
            ),
            (
                alarmPlan.shiftSoonEnabled,
                "\(identifierPrefix).shiftSoon",
                workdayPlan.shiftSoonTime,
                "Shift starts soon",
                "Your shift starts in \(commutePlan.shiftSoonAlertMinutes) minutes."
            )
        ]

        for alarm in alarms {
            guard alarm.enabled else { continue }
            let interval = alarm.date.timeIntervalSinceNow
            guard interval > 0 else { continue }

            let content = UNMutableNotificationContent()
            content.title = alarm.title
            content.body = alarm.body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: alarm.id, content: content, trigger: trigger)
            try? await center.add(request)
            identifiers.append(alarm.id)
        }

        return identifiers
    }

    public static func cancelAlarmNotifications(identifiers: [String]) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public static func cancelAllShiftAlarmNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(identifierPrefix) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
