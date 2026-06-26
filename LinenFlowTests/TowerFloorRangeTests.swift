import XCTest
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class TowerFloorRangeTests: XCTestCase {

    // MARK: - Core formula

    func test_3to31_skipOn_yields28() {
        let count = TowerFloorRange.deliveryFloorCount(startFloor: 3, topFloor: 31, skip13thFloor: true)
        XCTAssertEqual(count, 28)
    }

    func test_3to31_skipOff_yields29() {
        let count = TowerFloorRange.deliveryFloorCount(startFloor: 3, topFloor: 31, skip13thFloor: false)
        XCTAssertEqual(count, 29)
    }

    func test_14to31_skipOn_yields18_because13IsOutsideRange() {
        let count = TowerFloorRange.deliveryFloorCount(startFloor: 14, topFloor: 31, skip13thFloor: true)
        XCTAssertEqual(count, 18)
    }

    func test_singleFloor13_skipOn_yieldsZero_safelyPrevented() {
        let count = TowerFloorRange.deliveryFloorCount(startFloor: 13, topFloor: 13, skip13thFloor: true)
        XCTAssertEqual(count, 0)
        XCTAssertFalse(TowerFloorRange.isValid(startFloor: 13, topFloor: 13, skip13thFloor: true))
    }

    func test_topLowerThanStart_isRejected() {
        XCTAssertFalse(TowerFloorRange.isValid(startFloor: 10, topFloor: 5, skip13thFloor: false))
        XCTAssertEqual(TowerFloorRange.deliveryFloors(startFloor: 10, topFloor: 5, skip13thFloor: false), [])
    }

    func test_startFloorBelowOne_isRejected() {
        XCTAssertFalse(TowerFloorRange.isValid(startFloor: 0, topFloor: 10, skip13thFloor: false))
        XCTAssertEqual(TowerFloorRange.deliveryFloors(startFloor: 0, topFloor: 10, skip13thFloor: false), [])
    }

    // MARK: - Floor list contents

    func test_skipOn_floor13IsExcluded_whenInsideRange() {
        let floors = TowerFloorRange.deliveryFloors(startFloor: 3, topFloor: 31, skip13thFloor: true)
        XCTAssertFalse(floors.contains(13))
        XCTAssertEqual(floors.count, 28)
        XCTAssertEqual(floors.first, 3)
        XCTAssertEqual(floors.last, 31)
    }

    func test_skipOff_floor13IsIncluded_whenInsideRange() {
        let floors = TowerFloorRange.deliveryFloors(startFloor: 3, topFloor: 31, skip13thFloor: false)
        XCTAssertTrue(floors.contains(13))
        XCTAssertEqual(floors.count, 29)
    }

    func test_skipOn_floor13IsAbsent_butNotSubtracted_whenOutsideRange() {
        let floors = TowerFloorRange.deliveryFloors(startFloor: 14, topFloor: 31, skip13thFloor: true)
        XCTAssertFalse(floors.contains(13))
        XCTAssertEqual(floors.count, 18)
        XCTAssertEqual(floors.first, 14)
        XCTAssertEqual(floors.last, 31)
    }

    // MARK: - Summary text used for collapsed cards

    func test_summaryText_skipOn_insideRange() {
        let text = TowerFloorRange.summary(startFloor: 3, topFloor: 31, skip13thFloor: true)
        XCTAssertEqual(text, "Floors 3–31 · Skip 13 on · 28 delivery floors")
    }

    func test_summaryText_skipOff() {
        let text = TowerFloorRange.summary(startFloor: 3, topFloor: 31, skip13thFloor: false)
        XCTAssertEqual(text, "Floors 3–31 · 29 delivery floors")
    }

    func test_summaryText_invalidRange() {
        let text = TowerFloorRange.summary(startFloor: 10, topFloor: 5, skip13thFloor: false)
        XCTAssertEqual(text, "Set a valid floor range")
    }
}
