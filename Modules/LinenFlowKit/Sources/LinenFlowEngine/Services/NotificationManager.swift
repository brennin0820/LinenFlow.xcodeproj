import Foundation
import UserNotifications
import SwiftUI
import Combine
import LinenFlowCore

@MainActor
public class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()
    
    @Published public var isAuthorized = false
    
    @AppStorage("isReminderEnabled") public var isReminderEnabled: Bool = false {
        didSet {
            scheduleOrCancelReminders()
        }
    }
    
    @AppStorage("reminderHour") public var reminderHour: Int = 14 { // 2 PM default
        didSet {
            if isReminderEnabled { scheduleOrCancelReminders() }
        }
    }
    
    @AppStorage("reminderMinute") public var reminderMinute: Int = 0 {
        didSet {
            if isReminderEnabled { scheduleOrCancelReminders() }
        }
    }

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    public func requestAuthorization() async {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
            
            if granted {
                scheduleOrCancelReminders()
            }
        } catch {
            print("Failed to request authorization: \(error)")
        }
    }

    public func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized
    }

    public func scheduleOrCancelReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard isReminderEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "HimmerFlow Reminder"
        content.body = "It's time to log your daily par counts and linen distribution."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyShiftReminder", content: content, trigger: trigger)

        let h = reminderHour
        let m = reminderMinute

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule reminder: \(error)")
            } else {
                print("Reminder scheduled for \(h):\(String(format: "%02d", m)) daily")
            }
        }
    }
}
