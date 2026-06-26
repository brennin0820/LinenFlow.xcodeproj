import XCTest
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class DeliverySessionTests: XCTestCase {

    // MARK: - Delivery floor sequences

    func test_deliveryFloorSequence_tapaUsesFloorsThreeThroughThirtyFive() {
        let floors = DeliveryFloorSequenceService.deliveryFloors(towerName: "Tapa", floorCount: 35)

        XCTAssertEqual(floors.first, 3)
        XCTAssertEqual(floors.last, 35)
        XCTAssertEqual(floors.count, 33)
    }

    func test_deliveryFloorSequence_diamondUsesFifteenDeliveryFloors() {
        let floors = DeliveryFloorSequenceService.deliveryFloors(towerName: "Diamond", floorCount: 38)

        XCTAssertEqual(floors, Array(1...15))
    }

    func test_deliveryFloorSequence_aliiUsesFourteenDeliveryFloors() {
        let floors = DeliveryFloorSequenceService.deliveryFloors(towerName: "Alii", floorCount: 38)

        XCTAssertEqual(floors, Array(1...14))
    }

    func test_deliveryFloorSequence_gwUsesExplicitNonContinuousFloors() {
        let floors = DeliveryFloorSequenceService.deliveryFloors(towerName: "GW", floorCount: 39)

        XCTAssertEqual(floors.count, 32)
        XCTAssertEqual(floors.first, 5)
        XCTAssertEqual(floors.last, 39)
        XCTAssertFalse(floors.contains(13))
        XCTAssertFalse(floors.contains(33))
        XCTAssertFalse(floors.contains(34))
        XCTAssertTrue(floors.contains(12))
        XCTAssertTrue(floors.contains(14))
        XCTAssertTrue(floors.contains(32))
        XCTAssertTrue(floors.contains(35))
    }

    func test_deliveryFloorSequence_unknownTowerUsesOneThroughFloorCount() {
        let floors = DeliveryFloorSequenceService.deliveryFloors(towerName: "GenericUnknownTower", floorCount: 4)

        XCTAssertEqual(floors, [1, 2, 3, 4])
    }

    // MARK: - Delivery session progress

    func test_deliverySessionState_countsOnlyCompletedFloorsInRoute() {
        let state = DeliverySessionState(
            isActive: true,
            towerName: "GW",
            floorCount: 32,
            deliveryFloors: [5, 6, 7],
            completedFloorNumbers: [5, 99]
        )

        XCTAssertEqual(state.completedCount, 1)
        XCTAssertEqual(state.remainingCount, 2)
        XCTAssertEqual(state.progressFraction, 1.0 / 3.0, accuracy: 0.0001)
        XCTAssertFalse(state.isComplete)
    }

    func test_deliverySessionState_isCompleteWhenEveryRouteFloorIsDone() {
        let state = DeliverySessionState(
            isActive: true,
            towerName: "Diamond",
            floorCount: 3,
            deliveryFloors: [1, 2, 3],
            completedFloorNumbers: [1, 2, 3]
        )

        XCTAssertEqual(state.completedCount, 3)
        XCTAssertEqual(state.remainingCount, 0)
        XCTAssertEqual(state.progressFraction, 1.0, accuracy: 0.0001)
        XCTAssertTrue(state.isComplete)
    }

    func test_deliverySessionState_emptyRouteHasZeroProgressAndIsNotComplete() {
        let state = DeliverySessionState()

        XCTAssertEqual(state.completedCount, 0)
        XCTAssertEqual(state.remainingCount, 0)
        XCTAssertEqual(state.progressFraction, 0)
        XCTAssertFalse(state.isComplete)
    }
}
