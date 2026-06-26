import Foundation

#if canImport(ActivityKit)
import ActivityKit

public struct HimmerFlowDeliveryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var completedFloors: Int
        public var remainingFloors: Int
        public var currentItemName: String?
        public var currentItemNames: [String]? = nil
        public var currentTripItemNames: [String]? = nil
        public var currentFloorNumber: Int? = nil
        public var currentFloorDeliveryAmounts: [WidgetFloorDeliveryAmount]? = nil
        public var currentTripRemainingBundles: Int? = nil
        public var currentTripTotalBundles: Int? = nil
        public var nextCarryGroupTitle: String?
        public var statusText: String
        public var targetTime: Date?
        public var lastUpdated: Date
        public var isActiveSession: Bool
    }

    public var towerName: String
    public var floorCount: Int
    public var towerColorHex: String?
}
#endif
