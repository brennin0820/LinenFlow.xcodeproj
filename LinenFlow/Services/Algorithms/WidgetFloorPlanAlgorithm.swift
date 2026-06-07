import Foundation

enum WidgetFloorPlanAlgorithm {
    /// Builds up to `maxRows` compact top-down floor plan rows for a single delivery item.
    /// Adjacent ranges with the same value are merged; priority rows (isPlusOne) come first.
    static func buildRows(
        distributions: [FloorDistributionRow],
        itemName: String,
        unitIsBundles: Bool,
        maxRows: Int = 4
    ) -> [WidgetFloorPlanRow] {
        let itemRows = distributions.filter { $0.itemName == itemName }
        guard let group = FloorRangeBuilder.build(from: itemRows, unitIsBundles: unitIsBundles).first else {
            return []
        }

        var merged: [(value: Int, isPriority: Bool, segments: [String], floorCount: Int)] = []
        let topDownRanges = group.ranges.sorted { $0.firstFloor > $1.firstFloor }

        for range in topDownRanges {
            let segment = segmentLabel(for: range)
            if let index = merged.firstIndex(where: { $0.value == range.suggestedValue && $0.isPriority == range.isPlusOne }) {
                merged[index].segments.append(segment)
                merged[index].floorCount += rangeFloorCount(for: range)
            } else {
                merged.append((
                    value: range.suggestedValue,
                    isPriority: range.isPlusOne,
                    segments: [segment],
                    floorCount: rangeFloorCount(for: range)
                ))
            }
        }

        return merged.prefix(maxRows).map { row in
            let joined = row.segments.joined(separator: ", ")
            let label = row.segments.count == 1 && !joined.contains("-") ? "Floor \(joined)" : "Floors \(joined)"
            return WidgetFloorPlanRow(
                label: label,
                floorCount: row.floorCount,
                valueText: unitIsBundles ? "\(row.value) bdl" : "\(row.value) pcs",
                isPriority: row.isPriority
            )
        }
    }

    private static func rangeFloorCount(for range: FloorRange) -> Int {
        max(range.lastFloor - range.firstFloor + 1, 1)
    }

    private static func segmentLabel(for range: FloorRange) -> String {
        range.firstFloor == range.lastFloor ? "\(range.firstFloor)" : "\(range.lastFloor)-\(range.firstFloor)"
    }
}
