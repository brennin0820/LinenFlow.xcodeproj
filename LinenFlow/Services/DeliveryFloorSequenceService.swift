import Foundation

enum DeliveryFloorSequenceService {
    static func deliveryFloors(for tower: Tower?) -> [Int] {
        guard let tower else { return [] }
        if tower.hasCustomFloorRange {
            return TowerFloorRange.deliveryFloors(for: tower)
        }
        return deliveryFloors(towerName: tower.name, floorCount: tower.floorCount)
    }

    static func deliveryFloors(towerName: String, floorCount: Int) -> [Int] {
        guard floorCount > 0 else { return [] }

        let normalized = towerName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "‘", with: "'")

        switch normalized {
        case "tapa", "tapa tower":
            return Array(3...35)
        case "diamond", "diamond head", "diamond tower":
            return Array(1...15)
        case "alii", "ali'i", "alii tower", "ali'i tower":
            return Array(1...14)
        case "gw", "grand waikikian":
            // Authoritative legacy sequence from DefaultData seed (startFloor 0/0 → multi-gap floors).
            // Operational delivery starts at floor 5; floors 13, 33–34 are excluded by building policy.
            return Array(5...12) + Array(14...32) + Array(35...39)
        case "gi", "grand islander":
            // Authoritative legacy sequence from DefaultData seed (startFloor 4, topFloor 36, skip 13).
            // When floorCount matches seed (32), this yields floors 4…36 excluding 13.
            let giFloors = (4...38).filter { $0 != 13 }
            if floorCount <= giFloors.count {
                return Array(giFloors.prefix(floorCount))
            }
            let overflowStart = (giFloors.last ?? 38) + 1
            let overflowEnd = overflowStart + floorCount - giFloors.count - 1
            return giFloors + Array(overflowStart...overflowEnd)
        case "rainbow", "rainbow tower":
            return Array(2...12) + Array(14...31)
        case "kalia", "kalia tower":
            return Array(5...12) + Array(14...31)
        case "lagoon", "lagoon tower":
            // Note: 24 represents PH/Penthouse. Keeping as integer 24 for internal consistency.
            return Array(3...12) + Array(14...24)
        default:
            return Array(1...floorCount)
        }
    }
}
