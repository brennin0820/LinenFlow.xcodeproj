import Foundation

struct FloorRangeGroup {
    let itemName: String
    let ranges: [FloorRange]
    let unitIsBundles: Bool
}

struct FloorRange: Identifiable {
    let id = UUID()
    let firstFloor: Int
    let lastFloor: Int
    let suggestedValue: Int
    let isPlusOne: Bool

    var label: String {
        firstFloor == lastFloor ? "Floor \(firstFloor)" : "Floors \(firstFloor)–\(lastFloor)"
    }
}

enum FloorRangeBuilder {
    /// `unitIsBundles == true` reads `suggestedBundles`; otherwise reads `suggestedPieces`.
    static func build(from rows: [FloorDistributionRow], unitIsBundles: Bool = false) -> [FloorRangeGroup] {
        let extract: (FloorDistributionRow) -> Int = { row in
            unitIsBundles ? (row.suggestedBundles ?? 0) : row.suggestedPieces
        }

        let grouped = Dictionary(grouping: rows, by: { $0.itemName })
        return grouped
            .map { (itemName, itemRows) -> FloorRangeGroup in
                let sorted = itemRows.sorted { $0.floorNumber < $1.floorNumber }
                let values = Set(sorted.map(extract))
                let maxValue = values.max() ?? 0
                let hasRemainder = values.count > 1

                var ranges: [FloorRange] = []
                guard let first = sorted.first else {
                    return FloorRangeGroup(itemName: itemName, ranges: [], unitIsBundles: unitIsBundles)
                }

                var startFloor = first.floorNumber
                var lastFloor = first.floorNumber
                var currentValue = extract(first)

                for row in sorted.dropFirst() {
                    let v = extract(row)
                    if v == currentValue, row.floorNumber == lastFloor + 1 {
                        lastFloor = row.floorNumber
                    } else {
                        ranges.append(FloorRange(
                            firstFloor: startFloor,
                            lastFloor: lastFloor,
                            suggestedValue: currentValue,
                            isPlusOne: hasRemainder && currentValue == maxValue
                        ))
                        startFloor = row.floorNumber
                        lastFloor = row.floorNumber
                        currentValue = v
                    }
                }
                ranges.append(FloorRange(
                    firstFloor: startFloor,
                    lastFloor: lastFloor,
                    suggestedValue: currentValue,
                    isPlusOne: hasRemainder && currentValue == maxValue
                ))

                return FloorRangeGroup(itemName: itemName, ranges: ranges, unitIsBundles: unitIsBundles)
            }
            .sorted { $0.itemName < $1.itemName }
    }
}
