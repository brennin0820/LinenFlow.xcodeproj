import Foundation
import LinenFlowCore

public struct DoorOpeningPassRecommendation: Hashable, Sendable {
    public var itemName: String
    public var bundleCount: Int
    public var floorRangeText: String
    public var explanation: String
}

public struct DoorOpeningPassPlanner: Sendable {
    private let preferredItems = ["Washcloth", "Bath Mat", "Hand Towel", "Pillow Case"]

    public func recommendation(
        summaries: [CalculationSummary],
        deliveryRows: [FloorDistributionRow]
    ) -> DoorOpeningPassRecommendation? {
        let candidates = summaries.filter { $0.fullBundles > 0 || $0.receivedPieces > 0 }
        guard let selected = candidates.min(by: sortForDoorPass) else { return nil }
        let floors = deliveryRows
            .filter { $0.itemName == selected.itemName }
            .map(\.floorNumber)
            .sorted()
        let rangeText = floorRangeText(for: floors)
        let bundleCount = max(1, min(selected.fullBundles, 1))

        return DoorOpeningPassRecommendation(
            itemName: selected.itemName,
            bundleCount: bundleCount,
            floorRangeText: rangeText,
            explanation: "Carry \(bundleCount) bundle while opening \(rangeText)."
        )
    }

    private func sortForDoorPass(_ lhs: CalculationSummary, _ rhs: CalculationSummary) -> Bool {
        let lhsPriority = priority(for: lhs.itemName)
        let rhsPriority = priority(for: rhs.itemName)
        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }
        if lhs.fullBundles != rhs.fullBundles {
            return lhs.fullBundles < rhs.fullBundles
        }
        return lhs.itemName < rhs.itemName
    }

    private func priority(for itemName: String) -> Int {
        if let index = preferredItems.firstIndex(of: itemName) {
            return index
        }
        return preferredItems.count + 1
    }

    private func floorRangeText(for floors: [Int]) -> String {
        guard let first = floors.first, let last = floors.last else { return "assigned floors" }
        if first == last { return "Floor \(first)" }
        return "Floors \(first)-\(last)"
    }
}
