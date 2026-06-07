import Foundation
import UserNotifications

enum LeavingChecklistNotificationService {
    static let reminderIdentifier = "himmerflow.checklist.reminder"

    static func scheduleChecklistReminder(
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

    static func cancelChecklistReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
}
