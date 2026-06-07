import XCTest
@testable import HimmerFlow

final class TowerOperationalPolicyTests: XCTestCase {

    // MARK: - Confirmed delivery floor counts

    func test_confirmedFloorCount_gi_is32() {
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "GI"), 32)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Grand Islander"), 32)
    }

    func test_confirmedFloorCount_gw_is32() {
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "GW"), 32)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Grand Waikikian"), 32)
    }

    func test_confirmedFloorCount_tapa_is33() {
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Tapa"), 33)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Tapa Tower"), 33)
    }

    func test_confirmedFloorCount_diamond_is15() {
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Diamond"), 15)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Diamond Head"), 15)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Diamond Tower"), 15)
    }

    func test_confirmedFloorCount_alii_is14() {
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Alii"), 14)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Ali'i"), 14)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Alii Tower"), 14)
    }

    func test_confirmedFloorCount_lagoon_is21() {
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Lagoon"), 21)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Lagoon Tower"), 21)
    }

    func test_confirmedFloorCount_rainbow_is29() {
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Rainbow"), 29)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Rainbow Tower"), 29)
    }

    func test_confirmedFloorCount_kalia_is26() {
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Kalia"), 26)
        XCTAssertEqual(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Kalia Tower"), 26)
    }

    func test_confirmedFloorCount_unknown_isNil() {
        XCTAssertNil(TowerOperationalPolicy.confirmedDeliveryFloorCount(for: "Unknown Tower"))
    }

    // MARK: - Timeshare identification

    func test_timeshareTowers_lagoonGiGw() {
        XCTAssertTrue(TowerOperationalPolicy.isTimeshareTower("Lagoon"))
        XCTAssertTrue(TowerOperationalPolicy.isTimeshareTower("Lagoon Tower"))
        XCTAssertTrue(TowerOperationalPolicy.isTimeshareTower("GI"))
        XCTAssertTrue(TowerOperationalPolicy.isTimeshareTower("GW"))
    }

    func test_nonTimeshareTowers() {
        XCTAssertFalse(TowerOperationalPolicy.isTimeshareTower("Tapa"))
        XCTAssertFalse(TowerOperationalPolicy.isTimeshareTower("Diamond"))
        XCTAssertFalse(TowerOperationalPolicy.isTimeshareTower("Alii"))
        XCTAssertFalse(TowerOperationalPolicy.isTimeshareTower("Rainbow"))
        XCTAssertFalse(TowerOperationalPolicy.isTimeshareTower("Kalia"))
    }

    // MARK: - Delivery floor sequences for all seeded towers

    func test_allSeededTowers_haveNonEmptyDeliveryFloorSequence() {
        let seededNames = ["Lagoon", "GI", "GW", "Diamond", "Alii", "Tapa", "Rainbow", "Kalia"]
        let seededFloorCounts = [21, 32, 32, 15, 14, 33, 29, 26]

        for (name, count) in zip(seededNames, seededFloorCounts) {
            let floors = FloorNumberingService.deliveryFloors(towerName: name, floorCount: count)
            XCTAssertFalse(floors.isEmpty, "\(name) should have a non-empty delivery floor sequence")
            XCTAssertEqual(floors.count, count, "\(name) should have \(count) delivery floors")
        }
    }

    func test_gwFloorSequence_isExplicitNonContinuous() {
        let floors = FloorNumberingService.deliveryFloors(towerName: "GW", floorCount: 32)
        XCTAssertEqual(floors, Array(5...12) + Array(14...32) + Array(35...39))
        XCTAssertFalse(floors.contains(13))
        XCTAssertFalse(floors.contains(33))
        XCTAssertFalse(floors.contains(34))
    }

    func test_giFloorSequence_skips13_endsAt36() {
        let floors = FloorNumberingService.deliveryFloors(towerName: "GI", floorCount: 32)
        XCTAssertEqual(floors.first, 4)
        XCTAssertEqual(floors.last, 36)
        XCTAssertFalse(floors.contains(13))
        XCTAssertEqual(floors.count, 32)
    }

    func test_tapaFloorSequence_3through35() {
        let floors = FloorNumberingService.deliveryFloors(towerName: "Tapa", floorCount: 33)
        XCTAssertEqual(floors, Array(3...35))
    }

    func test_rainbowFloorSequence_skips13() {
        let floors = FloorNumberingService.deliveryFloors(towerName: "Rainbow", floorCount: 29)
        XCTAssertEqual(floors.first, 2)
        XCTAssertEqual(floors.last, 31)
        XCTAssertFalse(floors.contains(13))
        XCTAssertEqual(floors.count, 29)
    }

    func test_kaliaFloorSequence_skips13() {
        let floors = FloorNumberingService.deliveryFloors(towerName: "Kalia", floorCount: 26)
        XCTAssertEqual(floors.first, 5)
        XCTAssertEqual(floors.last, 31)
        XCTAssertFalse(floors.contains(13))
        XCTAssertEqual(floors.count, 26)
    }

    func test_lagoonFloorSequence_skips13() {
        let floors = FloorNumberingService.deliveryFloors(towerName: "Lagoon", floorCount: 21)
        XCTAssertEqual(floors.first, 3)
        XCTAssertEqual(floors.last, 24)
        XCTAssertFalse(floors.contains(13))
        XCTAssertEqual(floors.count, 21)
    }
}
