import Foundation
import LinenFlowCore

public enum FloorNumberingService {
    public static func deliveryFloors(for tower: Tower?) -> [Int] {
        guard let tower else { return [] }
        return deliveryFloors(towerName: tower.name, floorCount: tower.floorCount)
    }

    public static func deliveryFloors(towerName: String, floorCount: Int) -> [Int] {
        DeliveryFloorSequenceService.deliveryFloors(towerName: towerName, floorCount: floorCount)
    }

    public static func applyDisplayFloors(_ rows: [FloorDistributionRow], tower: Tower?) -> [FloorDistributionRow] {
        guard let tower else { return rows }
        let displayFloors = deliveryFloors(for: tower)
        guard !displayFloors.isEmpty else { return rows }

        return rows.map { row in
            guard row.floorNumber > 0, row.floorNumber <= displayFloors.count else { return row }
            var mapped = row
            mapped.floorNumber = displayFloors[row.floorNumber - 1]
            return mapped
        }
    }
}
