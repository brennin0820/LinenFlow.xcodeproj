import XCTest
@testable import HimmerFlow

final class FloorRebalanceServiceTests: XCTestCase {
    private let service = FloorRebalanceService()

    func test_bathTowelShortFloorsExample() throws {
        let result = try service.rebalanceShortFloors(FloorRebalanceRequest(
            itemName: "Bath Towel",
            originalPCS: 626,
            totalFloors: 32,
            originalPlan: bathTowelPlan,
            shortFloorStart: 21,
            shortFloorEnd: 24,
            pcsOnShortFloors: 0
        ))

        XCTAssertEqual(result.actualPCS, 550)
        XCTAssertEqual(result.missingPCS, 76)
        XCTAssertEqual(result.baseTarget, 17)
        XCTAssertEqual(result.remainder, 6)
        for floor in 1...6 {
            XCTAssertEqual(result.targets.first { $0.floorNumber == floor }?.targetPCS, 18)
        }
        for floor in 7...32 {
            XCTAssertEqual(result.targets.first { $0.floorNumber == floor }?.targetPCS, 17)
        }
        XCTAssertEqual(result.totalCollectBackPCS, 68)
        XCTAssertEqual(result.totalDeliverPCS, 68)
        XCTAssertTrue(result.isBalanced)

        XCTAssertEqual(
            compact(result.groupedActions.filter { $0.actionType == .collectBack }),
            [
                "1-6:collectBack:2:12",
                "7-18:collectBack:3:36",
                "19-20:collectBack:2:4",
                "25-32:collectBack:2:16"
            ]
        )
        XCTAssertEqual(
            compact(result.groupedActions.filter { $0.actionType == .deliver }),
            ["21-24:deliver:17:68"]
        )
    }

    func test_genericPillowCaseUsesPCSOnly() throws {
        let plan = (1...32).map {
            FloorDistributionRow(floorNumber: $0, itemName: "Pillow Case", suggestedPieces: 5)
        }

        let result = try service.rebalanceShortFloors(FloorRebalanceRequest(
            itemName: "Pillow Case",
            originalPCS: 160,
            totalFloors: 32,
            originalPlan: plan,
            shortFloorStart: 21,
            shortFloorEnd: 24,
            pcsOnShortFloors: 0
        ))

        XCTAssertEqual(result.itemName, "Pillow Case")
        XCTAssertEqual(result.actualPCS, 140)
        XCTAssertEqual(result.missingPCS, 20)
        XCTAssertEqual(result.baseTarget, 4)
        XCTAssertEqual(result.remainder, 12)
        XCTAssertTrue(result.isBalanced)
    }

    func test_invalidShortRangeThrowsValidationError() {
        XCTAssertThrowsError(try service.rebalanceShortFloors(FloorRebalanceRequest(
            itemName: "Bath Towel",
            originalPCS: 626,
            totalFloors: 32,
            originalPlan: bathTowelPlan,
            shortFloorStart: 24,
            shortFloorEnd: 21,
            pcsOnShortFloors: 0
        ))) { error in
            XCTAssertEqual(error as? FloorRebalanceError, .invalidShortRange)
        }
    }

    func test_shortRangeOutOfBoundsThrowsValidationError() {
        XCTAssertThrowsError(try service.rebalanceShortFloors(FloorRebalanceRequest(
            itemName: "Bath Towel",
            originalPCS: 626,
            totalFloors: 32,
            originalPlan: bathTowelPlan,
            shortFloorStart: 21,
            shortFloorEnd: 40,
            pcsOnShortFloors: 0
        ))) { error in
            XCTAssertEqual(error as? FloorRebalanceError, .shortRangeOutOfBounds)
        }
    }

    func test_missingOriginalPlanFloorThrowsValidationError() {
        let missingFloorPlan = bathTowelPlan.filter { $0.floorNumber != 32 }

        XCTAssertThrowsError(try service.rebalanceShortFloors(FloorRebalanceRequest(
            itemName: "Bath Towel",
            originalPCS: 626,
            totalFloors: 32,
            originalPlan: missingFloorPlan,
            shortFloorStart: 21,
            shortFloorEnd: 24,
            pcsOnShortFloors: 0
        ))) { error in
            XCTAssertEqual(error as? FloorRebalanceError, .missingFloor(32))
        }
    }

    func test_advancedManualModeSupportsMultipleWrongRanges() throws {
        let result = try service.rebalanceShortFloors(FloorRebalanceRequest(
            itemName: "Bath Towel",
            originalPCS: 626,
            totalFloors: 32,
            originalPlan: bathTowelPlan,
            shortFloorStart: 1,
            shortFloorEnd: 1,
            pcsOnShortFloors: 0,
            manualOverrideRanges: [
                FloorRebalanceOverrideRange(startFloor: 21, endFloor: 24, pcsEach: 0),
                FloorRebalanceOverrideRange(startFloor: 30, endFloor: 32, pcsEach: 10)
            ]
        ))

        XCTAssertEqual(result.actualPCS, 523)
        XCTAssertEqual(result.missingPCS, 103)
        XCTAssertEqual(result.baseTarget, 16)
        XCTAssertEqual(result.remainder, 11)
        XCTAssertTrue(result.isBalanced)
        XCTAssertEqual(result.totalCollectBackPCS, result.totalDeliverPCS)
        XCTAssertEqual(result.targets.first { $0.floorNumber == 21 }?.currentPCS, 0)
        XCTAssertEqual(result.targets.first { $0.floorNumber == 30 }?.currentPCS, 10)
    }

    func test_advancedManualModeRejectsOverlappingRanges() {
        XCTAssertThrowsError(try service.rebalanceShortFloors(FloorRebalanceRequest(
            itemName: "Bath Towel",
            originalPCS: 626,
            totalFloors: 32,
            originalPlan: bathTowelPlan,
            shortFloorStart: 1,
            shortFloorEnd: 1,
            pcsOnShortFloors: 0,
            manualOverrideRanges: [
                FloorRebalanceOverrideRange(startFloor: 21, endFloor: 24, pcsEach: 0),
                FloorRebalanceOverrideRange(startFloor: 24, endFloor: 26, pcsEach: 5)
            ]
        ))) { error in
            XCTAssertEqual(error as? FloorRebalanceError, .overlappingOverrideFloor(24))
        }
    }

    private var bathTowelPlan: [FloorDistributionRow] {
        (1...32).map { floor in
            FloorDistributionRow(
                floorNumber: floor,
                itemName: "Bath Towel",
                suggestedPieces: floor <= 18 ? 20 : 19
            )
        }
    }

    private func compact(_ actions: [FloorRebalanceAction]) -> [String] {
        actions.map {
            "\($0.startFloor)-\($0.endFloor):\($0.actionType.rawValue):\($0.pcsEach):\($0.totalPCS)"
        }
    }
}
