import Foundation

// Computed snapshot of an active delivery session used to drive the widget
// state, countdown display, and pace indicators throughout the app.
public struct DeliveryProgressSnapshot: Sendable {
    public let towerName: String
    public let towerAccentHex: String
    public let totalFloors: Int
    public let completedFloors: Int
    public let targetDownTime: Date
    public let deliveryStartedAt: Date?
    public let currentItemFocus: String?
    public let nextTripTitle: String?
    public let paceStatusLabel: String
    public let isDeliveryActive: Bool
    public let shiftStartHour: Int

    public var remainingFloors: Int { max(0, totalFloors - completedFloors) }
    public var progressFraction: Double { totalFloors > 0 ? Double(completedFloors) / Double(totalFloors) : 0 }
    public var minutesToTarget: Int { max(0, Int(targetDownTime.timeIntervalSinceNow / 60)) }

    public func asWidgetState() -> WidgetState {
        WidgetState(
            towerName: towerName,
            towerAccentHex: towerAccentHex,
            totalFloors: totalFloors,
            completedFloors: completedFloors,
            targetDownTime: targetDownTime,
            deliveryStartedAt: deliveryStartedAt,
            currentItemFocus: currentItemFocus,
            nextTripTitle: nextTripTitle,
            paceStatusLabel: paceStatusLabel,
            isDeliveryActive: isDeliveryActive,
            shiftStartHour: shiftStartHour
        )
    }

    public static func empty() -> DeliveryProgressSnapshot {
        DeliveryProgressSnapshot(
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
