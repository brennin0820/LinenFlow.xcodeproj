import Foundation

struct DeliverySessionState: Codable, Hashable, Sendable {
    var isActive: Bool = false
    var isPaused: Bool = false
    var towerName: String = ""
    var floorCount: Int = 0
    var deliveryFloors: [Int] = []
    var completedFloorNumbers: Set<Int> = []
    var currentItemName: String?
    var nextCarryGroupTitle: String?
    var startedAt: Date?
    var pausedAt: Date?
    var finishedAt: Date?

    var completedCount: Int {
        DeliverySessionProgressAlgorithm.completedCount(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        )
    }

    var remainingCount: Int {
        DeliverySessionProgressAlgorithm.remainingCount(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        )
    }

    var progressFraction: Double {
        DeliverySessionProgressAlgorithm.progressFraction(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        )
    }

    var isComplete: Bool {
        DeliverySessionProgressAlgorithm.isComplete(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        )
    }
}
