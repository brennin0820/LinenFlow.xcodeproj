import Foundation

struct WidgetPinnedItemSummary: Codable, Hashable {
    var itemName: String
    var bundles: Int
    var pieces: Int
    var loosePieces: Int
    var statusLabel: String
}

struct WidgetFloorPlanRow: Codable, Hashable {
    var label: String
    var floorCount: Int
    var valueText: String
    var isPriority: Bool
}

struct WidgetFloorDeliveryAmount: Codable, Hashable {
    var itemName: String
    var bundles: Int
    var loosePieces: Int

    var amountText: String {
        loosePieces > 0 ? "\(bundles) bdl + \(loosePieces) pcs" : "\(bundles) bdl"
    }
}

struct SharedWidgetState: Codable, Hashable {
    var towerName: String
    var towerColorHex: String?
    var floorCount: Int
    var completedFloors: Int
    var remainingFloors: Int
    var targetTime: Date?
    var shiftStartTime: Date?
    var shiftEndTime: Date?
    var currentItemName: String?
    var currentItemNames: [String]? = nil
    var currentTripItemNames: [String]? = nil
    var currentFloorNumber: Int? = nil
    var deliveryFloorNumbers: [Int]? = nil
    var completedFloorNumbers: [Int]? = nil
    var lastCompletedFloorNumber: Int? = nil
    var currentFloorDeliveryAmounts: [WidgetFloorDeliveryAmount]? = nil
    var floorDeliveryAmountsByFloor: [Int: [WidgetFloorDeliveryAmount]]? = nil
    var currentTripRemainingBundles: Int? = nil
    var currentTripTotalBundles: Int? = nil
    var currentItemFloorPlanTitle: String? = nil
    var currentItemFloorPlanRows: [WidgetFloorPlanRow]? = nil
    var pinnedItemSummaries: [WidgetPinnedItemSummary]? = nil
    var nextCarryGroupTitle: String?
    var statusText: String
    var lastUpdated: Date
    var isActiveSession: Bool
    var isPausedSession: Bool? = nil
    var isDemoDay: Bool

    var progressFraction: Double {
        guard floorCount > 0 else { return 0 }
        return min(max(Double(completedFloors) / Double(floorCount), 0), 1)
    }

    var completedText: String {
        "\(completedFloors)/\(floorCount)"
    }

    var countdownText: String {
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

    var shortTowerName: String {
        let trimmed = towerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "HF" }

        let words = trimmed.split(separator: " ")
        if words.count > 1 {
            return words.compactMap(\.first).prefix(2).map(String.init).joined().uppercased()
        }
        return String(trimmed.prefix(3)).uppercased()
    }
}
