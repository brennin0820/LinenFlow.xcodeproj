import Foundation

// Lightweight Codable snapshot of an active delivery session.
// Written to App Group UserDefaults by the main app; read by the widget extension.
// All properties use plain Swift value types so this type is implicitly Sendable.
public struct WidgetState: Codable, Sendable {
    public var towerName: String
    public var towerAccentHex: String
    public var totalFloors: Int
    public var completedFloors: Int
    public var targetDownTime: Date
    public var deliveryStartedAt: Date?
    public var currentItemFocus: String?
    public var nextTripTitle: String?
    public var paceStatusLabel: String
    public var isDeliveryActive: Bool
    public var shiftStartHour: Int

    public var remainingFloors: Int { max(0, totalFloors - completedFloors) }
    public var progressFraction: Double { totalFloors > 0 ? Double(completedFloors) / Double(totalFloors) : 0 }
    public var minutesToTarget: Int { max(0, Int(targetDownTime.timeIntervalSinceNow / 60)) }
    public var hoursToTarget: Int { minutesToTarget / 60 }
    public var minutesRemainder: Int { minutesToTarget % 60 }

    // Used by widget previews and placeholders.
    public static var placeholder: WidgetState {
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

    public static var empty: WidgetState {
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
