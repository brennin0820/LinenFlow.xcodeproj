import Foundation
import UserNotifications
import LinenFlowCore

public enum LeavingChecklistNotificationService {
    public static let reminderIdentifier = "himmerflow.checklist.reminder"

    public static func scheduleChecklistReminder(
        reminderTime: Date,
        items: [LeavingChecklistItem]
    ) async {
        let interval = reminderTime.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Leaving checklist"
        content.body = LeavingChecklistService.buildNotificationBody(from: items)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    public static func cancelChecklistReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
}
