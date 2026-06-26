import Foundation

public struct DeliverySessionState: Codable, Hashable, Sendable {
    public var isActive: Bool = false
    public var isPaused: Bool = false
    public var towerName: String = ""
    public var floorCount: Int = 0
    public var deliveryFloors: [Int] = []
    public var completedFloorNumbers: Set<Int> = []
    public var currentItemName: String?
    public var nextCarryGroupTitle: String?
    public var startedAt: Date?
    public var pausedAt: Date?
    public var finishedAt: Date?

    public var completedCount: Int {
        DeliverySessionProgressAlgorithm.completedCount(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        )
    }

    public var remainingCount: Int {
        DeliverySessionProgressAlgorithm.remainingCount(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        )
    }

    public var progressFraction: Double {
        DeliverySessionProgressAlgorithm.progressFraction(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        )
    }

    public var isComplete: Bool {
        DeliverySessionProgressAlgorithm.isComplete(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        )
    }
}
