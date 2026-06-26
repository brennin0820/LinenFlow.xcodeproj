import Foundation
import SwiftData
import LinenFlowCore

/// Tower configuration mutations shared by Settings and the Linen tab floor stepper.
public enum TowerConfigService {
    public static let minimumFloorCount = 1
    public static let maximumFloorCount = 80

    public enum FloorCountUpdateResult: Equatable {
        case updated(newCount: Int)
        case clampedToPolicy(protectedCount: Int)
        case unchanged
    }

    public enum FloorRangeUpdateResult: Equatable {
        case updated(floorCount: Int, floors: [Int])
        case invalidRange
    }

    /// Effective delivery floor count, honoring operational policy when set.
    public static func effectiveFloorCount(for tower: Tower) -> Int {
        if let protected = TowerOperationalPolicy.confirmedDeliveryFloorCount(for: tower) {
            return protected
        }
        if tower.hasCustomFloorRange {
            let floors = TowerFloorRange.deliveryFloors(for: tower)
            if !floors.isEmpty { return floors.count }
        }
        return max(tower.floorCount, minimumFloorCount)
    }

    /// Updates floor count when the tower is not policy-protected.
    @discardableResult
    public static func updateFloorCount(
        _ requestedCount: Int,
        for tower: Tower,
        context: ModelContext,
        now: Date = .now
    ) -> FloorCountUpdateResult {
        if let protectedCount = TowerOperationalPolicy.confirmedDeliveryFloorCount(for: tower) {
            if tower.floorCount != protectedCount {
                tower.floorCount = protectedCount
                tower.updatedAt = now
                try? context.save()
                return .clampedToPolicy(protectedCount: protectedCount)
            }
            return .unchanged
        }

        let clamped = min(max(requestedCount, minimumFloorCount), maximumFloorCount)
        guard tower.floorCount != clamped else { return .unchanged }

        tower.floorCount = clamped
        tower.updatedAt = now
        do {
            try context.save()
            return .updated(newCount: clamped)
        } catch {
            return .unchanged
        }
    }

    /// Applies a custom start/top range and recalculates `floorCount`.
    @discardableResult
    public static func updateFloorRange(
        startFloor: Int,
        topFloor: Int,
        skip13thFloor: Bool,
        for tower: Tower,
        context: ModelContext,
        now: Date = .now
    ) -> FloorRangeUpdateResult {
        let floors = TowerFloorRange.deliveryFloors(
            startFloor: startFloor,
            topFloor: topFloor,
            skip13thFloor: skip13thFloor
        )
        guard !floors.isEmpty else { return .invalidRange }

        tower.startFloor = startFloor
        tower.topFloor = topFloor
        tower.skip13thFloor = skip13thFloor
        tower.floorCount = floors.count
        tower.updatedAt = now

        do {
            try context.save()
            return .updated(floorCount: floors.count, floors: floors)
        } catch {
            return .invalidRange
        }
    }
}
