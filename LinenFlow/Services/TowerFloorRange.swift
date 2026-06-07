import Foundation

/// Builds the delivery floor sequence from editable tower range inputs.
///
/// The range is inclusive on both ends: `topFloor - startFloor + 1` is the base
/// count. When `skip13thFloor` is true AND floor 13 falls inside the range, the
/// 13th floor is removed and the count is one less.
enum TowerFloorRange {
    /// Lowest accepted start floor in the UI.
    static let minimumStartFloor = 1
    /// Largest accepted top floor in the UI. Matches the legacy stepper cap.
    static let maximumTopFloor = 99

    /// Returns the ordered delivery floor numbers for a given range.
    /// Returns an empty array for invalid ranges instead of crashing.
    static func deliveryFloors(startFloor: Int, topFloor: Int, skip13thFloor: Bool) -> [Int] {
        guard startFloor >= minimumStartFloor, topFloor >= startFloor else { return [] }
        var floors = Array(startFloor...topFloor)
        if skip13thFloor, startFloor <= 13, 13 <= topFloor {
            floors.removeAll { $0 == 13 }
        }
        return floors
    }

    /// Convenience overload for an already-validated tower configuration.
    static func deliveryFloors(for tower: Tower) -> [Int] {
        deliveryFloors(
            startFloor: tower.startFloor,
            topFloor: tower.topFloor,
            skip13thFloor: tower.skip13thFloor
        )
    }

    /// Calculated delivery floor count. `0` indicates an invalid range.
    static func deliveryFloorCount(startFloor: Int, topFloor: Int, skip13thFloor: Bool) -> Int {
        deliveryFloors(
            startFloor: startFloor,
            topFloor: topFloor,
            skip13thFloor: skip13thFloor
        ).count
    }

    /// True when the start/top values form a valid range and yield at least one floor.
    static func isValid(startFloor: Int, topFloor: Int, skip13thFloor: Bool) -> Bool {
        deliveryFloorCount(
            startFloor: startFloor,
            topFloor: topFloor,
            skip13thFloor: skip13thFloor
        ) >= 1
    }

    /// Human-readable summary for collapsed cards. Example:
    /// "Floors 3–31 · Skip 13 on · 28 delivery floors"
    static func summary(startFloor: Int, topFloor: Int, skip13thFloor: Bool) -> String {
        let count = deliveryFloorCount(
            startFloor: startFloor,
            topFloor: topFloor,
            skip13thFloor: skip13thFloor
        )
        guard count > 0 else { return "Set a valid floor range" }
        let rangeText = "Floors \(startFloor)–\(topFloor)"
        let skipText = (skip13thFloor && startFloor <= 13 && 13 <= topFloor) ? "Skip 13 on · " : ""
        let unitText = count == 1 ? "1 delivery floor" : "\(count) delivery floors"
        return "\(rangeText) · \(skipText)\(unitText)"
    }

    /// Plain-English math line shown under the calculated count.
    /// Examples:
    /// - "31 − 3 + 1 − 1 skipped floor = 28"
    /// - "31 − 3 + 1 = 29"
    /// - "31 − 14 + 1 = 18 · Floor 13 outside range"
    /// - "Invalid range: top floor must be higher than or equal to start floor"
    static func formulaText(startFloor: Int, topFloor: Int, skip13thFloor: Bool) -> String {
        guard startFloor >= minimumStartFloor, topFloor >= startFloor else {
            return "Invalid range: top floor must be higher than or equal to start floor"
        }
        let base = topFloor - startFloor + 1
        let isThirteenInside = startFloor <= 13 && 13 <= topFloor
        if skip13thFloor && isThirteenInside {
            return "\(topFloor) − \(startFloor) + 1 − 1 skipped floor = \(base - 1)"
        }
        if skip13thFloor && !isThirteenInside {
            return "\(topFloor) − \(startFloor) + 1 = \(base) · Floor 13 outside range"
        }
        return "\(topFloor) − \(startFloor) + 1 = \(base)"
    }

    /// Compresses a sorted floor list into "start–end" segments separated by ", ".
    /// Examples:
    /// - [3,4,5,…,12,14,…,31] => "3–12, 14–31"
    /// - [5,…,12,14,…,32,35,…,39] => "5–12, 14–32, 35–39"
    /// - [7] => "7"
    static func compactFloorList(_ floors: [Int]) -> String {
        guard !floors.isEmpty else { return "—" }
        var segments: [String] = []
        var rangeStart = floors[0]
        var rangeEnd = floors[0]
        for floor in floors.dropFirst() {
            if floor == rangeEnd + 1 {
                rangeEnd = floor
            } else {
                segments.append(rangeStart == rangeEnd ? "\(rangeStart)" : "\(rangeStart)–\(rangeEnd)")
                rangeStart = floor
                rangeEnd = floor
            }
        }
        segments.append(rangeStart == rangeEnd ? "\(rangeStart)" : "\(rangeStart)–\(rangeEnd)")
        return segments.joined(separator: ", ")
    }
}
