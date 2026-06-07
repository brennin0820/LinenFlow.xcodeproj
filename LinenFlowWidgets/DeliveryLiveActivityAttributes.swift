import ActivityKit
import Foundation

// Duplicate of the main app's DeliveryLiveActivityAttributes — must remain structurally identical.
// ActivityKit matches activities started by the app to the extension's UI by structural type identity.
struct DeliveryLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var completedFloors: Int
        var totalFloors: Int
        var targetDownTime: Date
        var deliveryStartedAt: Date?
        var currentItemFocus: String?
        var paceStatusLabel: String
        var isActive: Bool

        var remainingFloors: Int { max(0, totalFloors - completedFloors) }
        var progressFraction: Double {
            totalFloors > 0 ? Double(completedFloors) / Double(totalFloors) : 0
        }
        var minutesToTarget: Int {
            max(0, Int(targetDownTime.timeIntervalSinceNow / 60))
        }

        static var placeholder: ContentState {
            ContentState(
                completedFloors: 9,
                totalFloors: 15,
                targetDownTime: Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now,
                deliveryStartedAt: Calendar.current.date(byAdding: .hour, value: -1, to: .now),
                currentItemFocus: "Bath Towels",
                paceStatusLabel: "On Pace",
                isActive: true
            )
        }
    }

    let towerName: String
    let towerAccentHex: String
}
