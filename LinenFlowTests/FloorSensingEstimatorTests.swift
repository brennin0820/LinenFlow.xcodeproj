import XCTest
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class FloorSensingEstimatorTests: XCTestCase {

    private let routeFloors = [5, 6, 7, 8, 9, 10]

    func test_nearestValidFloor_snapsToClosestRouteFloor() {
        XCTAssertEqual(FloorSensingEstimator.nearestValidFloor(to: 7, in: routeFloors), 7)
        XCTAssertEqual(FloorSensingEstimator.nearestValidFloor(to: 8, in: routeFloors), 8)
        XCTAssertEqual(FloorSensingEstimator.nearestValidFloor(to: 99, in: routeFloors), 10)
    }

    func test_estimateFloor_belowMovementThreshold_staysOnStartFloorWithLowConfidence() {
        let result = FloorSensingEstimator.estimateFloor(
            startFloor: 7,
            altitudeDeltaMeters: 0.4,
            estimatedFloorHeightMeters: 3.1,
            movementThresholdMeters: 1.2,
            validFloors: routeFloors
        )

        XCTAssertEqual(result.estimatedFloor, 7)
        XCTAssertEqual(result.floorDelta, 0)
        XCTAssertEqual(result.confidence, .low)
        XCTAssertEqual(result.statusMessage, "Waiting for clear floor movement.")
    }

    func test_estimateFloor_oneFloorUp_highConfidence() {
        let result = FloorSensingEstimator.estimateFloor(
            startFloor: 7,
            altitudeDeltaMeters: 3.1,
            estimatedFloorHeightMeters: 3.1,
            movementThresholdMeters: 1.2,
            validFloors: routeFloors
        )

        XCTAssertEqual(result.estimatedFloor, 8)
        XCTAssertEqual(result.floorDelta, 1)
        XCTAssertEqual(result.confidence, .high)
    }

    func test_estimateFloor_oneFloorDown_highConfidence() {
        let result = FloorSensingEstimator.estimateFloor(
            startFloor: 7,
            altitudeDeltaMeters: -3.1,
            estimatedFloorHeightMeters: 3.1,
            movementThresholdMeters: 1.2,
            validFloors: routeFloors
        )

        XCTAssertEqual(result.estimatedFloor, 6)
        XCTAssertEqual(result.floorDelta, -1)
        XCTAssertEqual(result.confidence, .high)
    }

    func test_estimateFloor_outsideRouteNeedsCorrection() {
        let result = FloorSensingEstimator.estimateFloor(
            startFloor: 5,
            altitudeDeltaMeters: -18.6,
            estimatedFloorHeightMeters: 3.1,
            movementThresholdMeters: 1.2,
            validFloors: routeFloors
        )

        XCTAssertEqual(result.estimatedFloor, 5)
        XCTAssertEqual(result.confidence, .needsCorrection)
        XCTAssertEqual(result.statusMessage, "Outside route — correction may be needed.")
    }

    func test_estimateFloor_emptyRouteNeedsCorrection() {
        let result = FloorSensingEstimator.estimateFloor(
            startFloor: 7,
            altitudeDeltaMeters: 3.1,
            estimatedFloorHeightMeters: 3.1,
            movementThresholdMeters: 1.2,
            validFloors: []
        )

        XCTAssertEqual(result.estimatedFloor, 7)
        XCTAssertEqual(result.confidence, .needsCorrection)
        XCTAssertEqual(result.statusMessage, "No valid route floors are available.")
    }

    func test_estimateFloor_uncalibratedTowerHeightNeedsCorrection() {
        let result = FloorSensingEstimator.estimateFloor(
            startFloor: 7,
            altitudeDeltaMeters: 3.1,
            estimatedFloorHeightMeters: 0,
            movementThresholdMeters: 1.2,
            validFloors: routeFloors
        )

        XCTAssertEqual(result.estimatedFloor, 7)
        XCTAssertEqual(result.confidence, .needsCorrection)
        XCTAssertEqual(result.statusMessage, "Tower floor height is not calibrated.")
    }
}
