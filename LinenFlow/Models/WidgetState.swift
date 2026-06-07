import Foundation

// Lightweight Codable snapshot of an active delivery session.
// Written to App Group UserDefaults by the main app; read by the widget extension.
// All properties use plain Swift value types so this type is implicitly Sendable.
struct WidgetState: Codable, Sendable {
    var towerName: String
    var towerAccentHex: String
    var totalFloors: Int
    var completedFloors: Int
    var targetDownTime: Date
    var deliveryStartedAt: Date?
    var currentItemFocus: String?
    var nextTripTitle: String?
    var paceStatusLabel: String
    var isDeliveryActive: Bool
    var shiftStartHour: Int

    var remainingFloors: Int { max(0, totalFloors - completedFloors) }
    var progressFraction: Double { totalFloors > 0 ? Double(completedFloors) / Double(totalFloors) : 0 }
    var minutesToTarget: Int { max(0, Int(targetDownTime.timeIntervalSinceNow / 60)) }
    var hoursToTarget: Int { minutesToTarget / 60 }
    var minutesRemainder: Int { minutesToTarget % 60 }

    // Used by widget previews and placeholders.
    static var placeholder: WidgetState {
        WidgetState(
            towerName: "Diamond",
            towerAccentHex: "#7C878E",
            totalFloors: 15,
            completedFloors: 9,
            targetDownTime: Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now,
            deliveryStartedAt: Calendar.current.date(byAdding: .hour, value: -1, to: .now),
            currentItemFocus: "Bath Towels",
            nextTripTitle: "WC + HT Carry",
            paceStatusLabel: "On Pace",
            isDeliveryActive: true,
            shiftStartHour: 7
        )
    }

    static var empty: WidgetState {
        WidgetState(
            towerName: "--",
            towerAccentHex: "#2F6F8F",
            totalFloors: 0,
            completedFloors: 0,
            targetDownTime: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: .now) ?? .now,
            deliveryStartedAt: nil,
            currentItemFocus: nil,
            nextTripTitle: nil,
            paceStatusLabel: "Not Started",
            isDeliveryActive: false,
            shiftStartHour: 7
        )
    }
}
