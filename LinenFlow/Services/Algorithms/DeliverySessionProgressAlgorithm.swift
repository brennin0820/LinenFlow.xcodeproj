import Foundation

enum DeliverySessionProgressAlgorithm {
    static func completedCount(_ completedFloorNumbers: Set<Int>) -> Int {
        completedFloorNumbers.count
    }

    static func completedCount(deliveryFloors: [Int], completedFloorNumbers: Set<Int>) -> Int {
        guard !deliveryFloors.isEmpty else { return 0 }
        return completedFloorNumbers.intersection(Set(deliveryFloors)).count
    }

    static func remainingCount(floorCount: Int, completedFloorNumbers: Set<Int>) -> Int {
        max(0, floorCount - completedFloorNumbers.count)
    }

    static func remainingCount(deliveryFloors: [Int], completedFloorNumbers: Set<Int>) -> Int {
        max(deliveryFloors.count - completedCount(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        ), 0)
    }

    static func progressFraction(floorCount: Int, completedFloorNumbers: Set<Int>) -> Double {
        guard floorCount > 0 else { return 0 }
        return min(max(Double(completedFloorNumbers.count) / Double(floorCount), 0), 1)
    }

    static func progressFraction(deliveryFloors: [Int], completedFloorNumbers: Set<Int>) -> Double {
        guard !deliveryFloors.isEmpty else { return 0 }
        let completed = completedCount(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        )
        return min(max(Double(completed) / Double(deliveryFloors.count), 0), 1)
    }

    static func isComplete(floorCount: Int, completedFloorNumbers: Set<Int>) -> Bool {
        floorCount > 0 && completedFloorNumbers.count >= floorCount
    }

    static func isComplete(deliveryFloors: [Int], completedFloorNumbers: Set<Int>) -> Bool {
        !deliveryFloors.isEmpty && completedCount(
            deliveryFloors: deliveryFloors,
            completedFloorNumbers: completedFloorNumbers
        ) >= deliveryFloors.count
    }
}
