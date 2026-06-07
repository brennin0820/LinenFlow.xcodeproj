import Foundation

struct FloorEstimateResult: Equatable, Sendable {
    let estimatedFloor: Int
    let floorDelta: Int
    let confidence: FloorSensingConfidence
    let statusMessage: String
}

enum FloorSensingEstimator {
    static func estimateFloor(
        startFloor: Int,
        altitudeDeltaMeters: Double,
        estimatedFloorHeightMeters: Double,
        movementThresholdMeters: Double,
        validFloors: [Int]
    ) -> FloorEstimateResult {
        let routeFloors = Array(Set(validFloors)).sorted()

        guard !routeFloors.isEmpty else {
            return FloorEstimateResult(
                estimatedFloor: startFloor,
                floorDelta: 0,
                confidence: .needsCorrection,
                statusMessage: "No valid route floors are available."
            )
        }

        let nearestStartFloor = nearestValidFloor(to: startFloor, in: routeFloors)

        guard estimatedFloorHeightMeters > 0 else {
            return FloorEstimateResult(
                estimatedFloor: nearestStartFloor,
                floorDelta: 0,
                confidence: .needsCorrection,
                statusMessage: "Tower floor height is not calibrated."
            )
        }

        let threshold = max(0, movementThresholdMeters)
        guard abs(altitudeDeltaMeters) >= threshold else {
            return FloorEstimateResult(
                estimatedFloor: nearestStartFloor,
                floorDelta: 0,
                confidence: .low,
                statusMessage: "Waiting for clear floor movement."
            )
        }

        let rawDelta = altitudeDeltaMeters / estimatedFloorHeightMeters
        let roundedDelta = Int(rawDelta.rounded())
        let candidate = startFloor + roundedDelta
        let snappedFloor = nearestValidFloor(to: candidate, in: routeFloors)
        let minFloor = routeFloors[0]
        let maxFloor = routeFloors[routeFloors.count - 1]
        let isOutsideRoute = candidate < minFloor || candidate > maxFloor
        let didSnap = snappedFloor != candidate
        let remainderFromWholeFloor = abs(rawDelta - rawDelta.rounded())

        let confidence: FloorSensingConfidence
        if isOutsideRoute && abs(candidate - snappedFloor) > 1 {
            confidence = .needsCorrection
        } else if remainderFromWholeFloor <= 0.25 {
            confidence = .high
        } else if remainderFromWholeFloor <= 0.45 {
            confidence = .medium
        } else {
            confidence = .low
        }

        let statusMessage: String
        if isOutsideRoute {
            statusMessage = "Outside route — correction may be needed."
        } else if didSnap {
            statusMessage = "Snapped to nearest delivery floor."
        } else {
            statusMessage = "Estimated from altitude movement."
        }

        return FloorEstimateResult(
            estimatedFloor: snappedFloor,
            floorDelta: roundedDelta,
            confidence: confidence,
            statusMessage: statusMessage
        )
    }

    static func nearestValidFloor(to floor: Int, in validFloors: [Int]) -> Int {
        let routeFloors = Array(Set(validFloors)).sorted()
        guard let first = routeFloors.first else { return floor }
        return routeFloors.min { lhs, rhs in
            let lhsDistance = abs(lhs - floor)
            let rhsDistance = abs(rhs - floor)
            if lhsDistance == rhsDistance {
                return lhs < rhs
            }
            return lhsDistance < rhsDistance
        } ?? first
    }
}
