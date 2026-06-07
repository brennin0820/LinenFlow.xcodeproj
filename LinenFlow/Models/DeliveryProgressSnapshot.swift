import Foundation

// Computed snapshot of an active delivery session used to drive the widget
// state, countdown display, and pace indicators throughout the app.
struct DeliveryProgressSnapshot: Sendable {
    let towerName: String
    let towerAccentHex: String
    let totalFloors: Int
    let completedFloors: Int
    let targetDownTime: Date
    let deliveryStartedAt: Date?
    let currentItemFocus: String?
    let nextTripTitle: String?
    let paceStatusLabel: String
    let isDeliveryActive: Bool
    let shiftStartHour: Int

    var remainingFloors: Int { max(0, totalFloors - completedFloors) }
    var progressFraction: Double { totalFloors > 0 ? Double(completedFloors) / Double(totalFloors) : 0 }
    var minutesToTarget: Int { max(0, Int(targetDownTime.timeIntervalSinceNow / 60)) }

    func asWidgetState() -> WidgetState {
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

    static func empty() -> DeliveryProgressSnapshot {
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
