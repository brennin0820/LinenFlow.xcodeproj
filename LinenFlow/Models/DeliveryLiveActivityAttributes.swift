import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct HimmerFlowDeliveryAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var completedFloors: Int
        var remainingFloors: Int
        var currentItemName: String?
        var currentItemNames: [String]? = nil
        var currentTripItemNames: [String]? = nil
        var currentFloorNumber: Int? = nil
        var currentFloorDeliveryAmounts: [WidgetFloorDeliveryAmount]? = nil
        var currentTripRemainingBundles: Int? = nil
        var currentTripTotalBundles: Int? = nil
        var nextCarryGroupTitle: String?
        var statusText: String
        var targetTime: Date?
        var lastUpdated: Date
        var isActiveSession: Bool
    }

    var towerName: String
    var floorCount: Int
    var towerColorHex: String?
}
#endif
