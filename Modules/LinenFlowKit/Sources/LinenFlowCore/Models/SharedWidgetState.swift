import Foundation

public struct WidgetPinnedItemSummary: Codable, Hashable {
    public var itemName: String
    public var bundles: Int
    public var pieces: Int
    public var loosePieces: Int
    public var statusLabel: String
}

public struct WidgetFloorPlanRow: Codable, Hashable {
    public var label: String
    public var floorCount: Int
    public var valueText: String
    public var isPriority: Bool
}

public struct WidgetFloorDeliveryAmount: Codable, Hashable {
    public var itemName: String
    public var bundles: Int
    public var loosePieces: Int

    public var amountText: String {
        loosePieces > 0 ? "\(bundles) bdl + \(loosePieces) pcs" : "\(bundles) bdl"
    }
}

public struct SharedWidgetState: Codable, Hashable {
    public var towerName: String
    public var towerColorHex: String?
    public var floorCount: Int
    public var completedFloors: Int
    public var remainingFloors: Int
    public var targetTime: Date?
    public var shiftStartTime: Date?
    public var shiftEndTime: Date?
    public var currentItemName: String?
    public var currentItemNames: [String]? = nil
    public var currentTripItemNames: [String]? = nil
    public var currentFloorNumber: Int? = nil
    public var deliveryFloorNumbers: [Int]? = nil
    public var completedFloorNumbers: [Int]? = nil
    public var lastCompletedFloorNumber: Int? = nil
    public var currentFloorDeliveryAmounts: [WidgetFloorDeliveryAmount]? = nil
    public var floorDeliveryAmountsByFloor: [Int: [WidgetFloorDeliveryAmount]]? = nil
    public var currentTripRemainingBundles: Int? = nil
    public var currentTripTotalBundles: Int? = nil
    public var currentItemFloorPlanTitle: String? = nil
    public var currentItemFloorPlanRows: [WidgetFloorPlanRow]? = nil
    public var pinnedItemSummaries: [WidgetPinnedItemSummary]? = nil
    public var nextCarryGroupTitle: String?
    public var statusText: String
    public var lastUpdated: Date
    public var isActiveSession: Bool
    public var isPausedSession: Bool? = nil
    public var isDemoDay: Bool

    public var progressFraction: Double {
        guard floorCount > 0 else { return 0 }
        return min(max(Double(completedFloors) / Double(floorCount), 0), 1)
    }

    public var completedText: String {
        "\(completedFloors)/\(floorCount)"
    }

    public var countdownText: String {
        guard let targetTime else { return statusText }
        let raw = targetTime.timeIntervalSinceNow
        if raw < 0 {
            let over = Int(-raw / 60) + 1
            return "Overtime +\(over)m"
        }
        let seconds = Int(raw)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m left" }
        if minutes > 0 { return "\(minutes)m left" }
        return "Due now"
    }

    public var shortTowerName: String {
        let trimmed = towerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "HF" }

        let words = trimmed.split(separator: " ")
        if words.count > 1 {
            return words.compactMap(\.first).prefix(2).map(String.init).joined().uppercased()
        }
        return String(trimmed.prefix(3)).uppercased()
    }
}
