import Foundation

enum TowerOperationalPolicy {
    static func confirmedDeliveryFloorCount(for towerName: String) -> Int? {
        let normalized = towerName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "‘", with: "'")

        switch normalized {
        case "gw", "grand waikikian":
            return 32
        case "gi", "grand islander":
            return 32
        case "tapa", "tapa tower":
            return 33
        case "diamond", "diamond head", "diamond tower":
            return 15
        case "alii", "ali'i", "alii tower", "ali'i tower":
            return 14
        case "rainbow", "rainbow tower":
            return 29
        case "kalia", "kalia tower":
            return 26
        case "lagoon", "lagoon tower":
            return 21
        default:
            return nil
        }
    }

    static func confirmedDeliveryFloorCount(for tower: Tower?) -> Int? {
        guard let tower else { return nil }
        return confirmedDeliveryFloorCount(for: tower.name)
    }

    static func hasProtectedDeliveryFloorCount(_ tower: Tower?) -> Bool {
        confirmedDeliveryFloorCount(for: tower) != nil
    }

    static func isTimeshareTower(_ towerName: String) -> Bool {
        let normalized = towerName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let variants: Set<String> = ["lagoon", "lagoon tower", "gi", "grand islander", "gw", "grand waikikian"]
        return variants.contains(normalized)
    }

    static func allowsStrategyPlanning(for tower: Tower?) -> Bool {
        guard let tower else { return false }
        return !isTimeshareTower(tower.name)
    }

    static func usesParSystem(for tower: Tower?) -> Bool {
        guard let tower else { return false }
        return !isTimeshareTower(tower.name)
    }
}
