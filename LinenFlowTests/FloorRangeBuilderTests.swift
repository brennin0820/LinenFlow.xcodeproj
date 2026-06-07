import XCTest
@testable import HimmerFlow

final class FloorRangeBuilderTests: XCTestCase {

    func makeRow(_ floor: Int, item: String, pieces: Int, bundles: Int? = nil) -> FloorDistributionRow {
        FloorDistributionRow(floorNumber: floor, itemName: item, suggestedPieces: pieces, suggestedBundles: bundles)
    }

    func test_consecutiveIdenticalValues_combineIntoOneRange() {
        let rows = (1...5).map { makeRow($0, item: "Bath Towel", pieces: 10) }
        let groups = FloorRangeBuilder.build(from: rows, unitIsBundles: false)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].ranges.count, 1)
        XCTAssertEqual(groups[0].ranges[0].firstFloor, 1)
        XCTAssertEqual(groups[0].ranges[0].lastFloor, 5)
        XCTAssertEqual(groups[0].ranges[0].suggestedValue, 10)
    }

    func test_remainderFloors_splitIntoTwoRanges() {
        // first 3 floors get 11, rest get 10
        var rows = (1...3).map { makeRow($0, item: "Bath Towel", pieces: 11) }
        rows += (4...7).map { makeRow($0, item: "Bath Towel", pieces: 10) }
        let groups = FloorRangeBuilder.build(from: rows, unitIsBundles: false)
        XCTAssertEqual(groups[0].ranges.count, 2)
        XCTAssertEqual(groups[0].ranges[0].suggestedValue, 11)
        XCTAssertTrue(groups[0].ranges[0].isPlusOne)
        XCTAssertEqual(groups[0].ranges[1].suggestedValue, 10)
        XCTAssertFalse(groups[0].ranges[1].isPlusOne)
    }

    func test_zeroValueFloors_includedInRanges() {
        let rows = (1...3).map { makeRow($0, item: "Bath Towel", pieces: 0) }
        let groups = FloorRangeBuilder.build(from: rows, unitIsBundles: false)
        XCTAssertEqual(groups[0].ranges.count, 1)
        XCTAssertEqual(groups[0].ranges[0].suggestedValue, 0)
    }

    func test_bundleMode_readsSuggestedBundles() {
        let rows = (1...4).map { makeRow($0, item: "Double Cover", pieces: 0, bundles: 2) }
        let groups = FloorRangeBuilder.build(from: rows, unitIsBundles: true)
        XCTAssertEqual(groups[0].ranges.count, 1)
        XCTAssertEqual(groups[0].ranges[0].suggestedValue, 2)
    }

    func test_multipleItems_produceSeparateGroups() {
        let rows = (1...2).map { makeRow($0, item: "Bath Towel", pieces: 5) }
                + (1...2).map { makeRow($0, item: "Bath Mat", pieces: 3) }
        let groups = FloorRangeBuilder.build(from: rows, unitIsBundles: false)
        XCTAssertEqual(groups.count, 2)
        let names = Set(groups.map(\.itemName))
        XCTAssertTrue(names.contains("Bath Towel"))
        XCTAssertTrue(names.contains("Bath Mat"))
    }

    func test_nonContinuousFloors_createsSeparateRanges() {
        // GW-style: floors 1, 3, 5, 7 (gaps between each)
        let rows = [1, 3, 5, 7].map { makeRow($0, item: "Bath Towel", pieces: 10) }
        let groups = FloorRangeBuilder.build(from: rows, unitIsBundles: false)
        XCTAssertEqual(groups.count, 1)
        // Each non-consecutive floor should be its own range
        XCTAssertEqual(groups[0].ranges.count, 4)
        XCTAssertEqual(groups[0].ranges[0].firstFloor, 1)
        XCTAssertEqual(groups[0].ranges[0].lastFloor, 1)
    }

    func test_mixedContinuousAndGaps_handlesCorrectly() {
        // Floors 3,4,5 (continuous) then gap then 8,9 (continuous)
        let rows = [3, 4, 5, 8, 9].map { makeRow($0, item: "Hand Towel", pieces: 5) }
        let groups = FloorRangeBuilder.build(from: rows, unitIsBundles: false)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].ranges.count, 2)
        XCTAssertEqual(groups[0].ranges[0].label, "Floors 3–5")
        XCTAssertEqual(groups[0].ranges[1].label, "Floors 8–9")
    }

    func test_singleFloor_createsOneRange() {
        let rows = [makeRow(10, item: "Washcloth", pieces: 3)]
        let groups = FloorRangeBuilder.build(from: rows, unitIsBundles: false)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].ranges.count, 1)
        XCTAssertEqual(groups[0].ranges[0].label, "Floor 10")
    }
}
