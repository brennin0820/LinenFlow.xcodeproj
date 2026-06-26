import Foundation
import UserNotifications
import LinenFlowCore

public enum ShiftNotificationService {
    public static let hourlyIDs = (1...12).map { "himmerflow.hourly.\($0)" }

    public static func schedule(startTime: Date, targetTime: Date) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                enqueue(center: center, startTime: startTime, targetTime: targetTime)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    guard granted else { return }
                    enqueue(center: center, startTime: startTime, targetTime: targetTime)
                }
            default:
                break
            }
        }
    }

    public static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: hourlyIDs)
    }

    private static func enqueue(center: UNUserNotificationCenter, startTime: Date, targetTime: Date) {
        center.removePendingNotificationRequests(withIdentifiers: hourlyIDs)
        let targetFormatted = targetTime.formatted(date: .omitted, time: .shortened)

        for hour in 1...12 {
            let fireDate = startTime.addingTimeInterval(Double(hour) * 3600)
            guard fireDate < targetTime else { break }
            let interval = fireDate.timeIntervalSinceNow
            guard interval > 0 else { continue }

            let remaining = targetTime.timeIntervalSince(fireDate)
            let rh = Int(remaining) / 3600
            let rm = (Int(remaining) % 3600) / 60

            let content = UNMutableNotificationContent()
            content.title = "\(hour)h elapsed — HimmerFlow"
            content.body = rh > 0 ? "\(rh)h \(rm)m until \(targetFormatted)." : "\(rm)m until \(targetFormatted)."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            center.add(UNNotificationRequest(identifier: "himmerflow.hourly.\(hour)", content: content, trigger: trigger))
        }
    }
}
