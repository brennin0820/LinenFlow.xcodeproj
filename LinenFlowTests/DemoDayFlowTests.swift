import XCTest
import SwiftData
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

/// End-to-end assertions on the full Demo Day fixture from the build prompt.
/// Many top-level assertions overlap with FlowViewModelTests; this file pins
/// the per-floor distribution numbers required by Task 17 / Task 20.
@MainActor
final class DemoDayFlowTests: XCTestCase {

    var container: ModelContainer!
    var viewModel: FlowViewModel!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Tower.self, LinenItem.self, DailyLog.self,
            configurations: config
        )
        SeedService.seedIfNeeded(context: container.mainContext)
        viewModel = FlowViewModel(modelContext: container.mainContext)
        viewModel.loadDemoDay()
    }

    override func tearDownWithError() throws {
        viewModel = nil
        container = nil
    }

    // MARK: - Per-item base + remainder

    func test_bathTowel_base23_remainder7() {
        let s = summary(for: "Bath Towel")
        XCTAssertEqual(s?.basePerFloorPieces, 23)
        XCTAssertEqual(s?.remainderPieces, 7)
    }

    func test_bathMat_base2_remainder18() {
        let s = summary(for: "Bath Mat")
        XCTAssertEqual(s?.basePerFloorPieces, 2)
        XCTAssertEqual(s?.remainderPieces, 18)
    }

    func test_handTowel_base4_remainder16() {
        let s = summary(for: "Hand Towel")
        XCTAssertEqual(s?.basePerFloorPieces, 4)
        XCTAssertEqual(s?.remainderPieces, 16)
    }

    func test_washcloth_base1_remainder19() {
        let s = summary(for: "Washcloth")
        XCTAssertEqual(s?.basePerFloorPieces, 1)
        XCTAssertEqual(s?.remainderPieces, 19)
    }

    func test_pillowCase_base4_remainder6() {
        let s = summary(for: "Pillow Case")
        XCTAssertEqual(s?.basePerFloorPieces, 4)
        XCTAssertEqual(s?.remainderPieces, 6)
    }

    // MARK: - Floor-by-floor distribution

    func test_bathTowel_distribution_first7Floors24_rest23() {
        let rows = floors(for: "Bath Towel")
        XCTAssertEqual(rows.count, 21)
        for i in 0..<7 {
            XCTAssertEqual(rows[i].suggestedPieces, 24,
                           "Bath Towel floor \(rows[i].floorNumber) should get 24 pcs")
        }
        for i in 7..<21 {
            XCTAssertEqual(rows[i].suggestedPieces, 23,
                           "Bath Towel floor \(rows[i].floorNumber) should get 23 pcs")
        }
    }

    func test_bathMat_distribution_first18Floors3_rest2() {
        let rows = floors(for: "Bath Mat")
        XCTAssertEqual(rows.count, 21)
        for i in 0..<18 {
            XCTAssertEqual(rows[i].suggestedPieces, 3,
                           "Bath Mat floor \(rows[i].floorNumber) should get 3 pcs")
        }
        for i in 18..<21 {
            XCTAssertEqual(rows[i].suggestedPieces, 2,
                           "Bath Mat floor \(rows[i].floorNumber) should get 2 pcs")
        }
    }

    // MARK: - Demo Day flag + reset

    func test_isDemoDayFlag_setAfterLoad() {
        XCTAssertTrue(viewModel.isDemoDay)
    }

    func test_resetFlow_clearsDemoFlag() {
        viewModel.resetFlow()
        XCTAssertFalse(viewModel.isDemoDay)
        XCTAssertNil(viewModel.selectedTower)
        XCTAssertTrue(viewModel.receivingEntries.isEmpty)
    }

    // MARK: - Settings independence

    func test_demoDay_doesNotMutateLinenItems() throws {
        let beforePar = try container.mainContext
            .fetch(FetchDescriptor<LinenItem>())
            .first(where: { $0.name == "Bath Towel" })?
            .parCount
        XCTAssertEqual(beforePar, 14, "expected seeded par = 14")
    }

    // MARK: - FloorRangeBuilder

    func test_bathTowelRanges_collapseToThreeRanges() {
        let rows = floors(for: "Bath Towel")
        let group = FloorRangeBuilder.build(from: rows).first { $0.itemName == "Bath Towel" }
        XCTAssertEqual(group?.ranges.count, 3)
        let highRange = group?.ranges.first { $0.suggestedValue == 24 }
        let lowRange1 = group?.ranges.first { $0.suggestedValue == 23 && $0.firstFloor == 10 }
        let lowRange2 = group?.ranges.first { $0.suggestedValue == 23 && $0.firstFloor == 14 }
        
        XCTAssertEqual(highRange?.firstFloor, 3)
        XCTAssertEqual(highRange?.lastFloor, 9)
        XCTAssertEqual(highRange?.isPlusOne, true)
        
        XCTAssertEqual(lowRange1?.firstFloor, 10)
        XCTAssertEqual(lowRange1?.lastFloor, 12)
        XCTAssertEqual(lowRange1?.isPlusOne, false)
        
        XCTAssertEqual(lowRange2?.firstFloor, 14)
        XCTAssertEqual(lowRange2?.lastFloor, 24)
        XCTAssertEqual(lowRange2?.isPlusOne, false)
    }

    // MARK: - Helpers

    private func summary(for itemName: String) -> CalculationSummary? {
        viewModel.calculationSummaries.first { $0.itemName == itemName }
    }

    private func floors(for itemName: String) -> [FloorDistributionRow] {
        viewModel.floorDistributions
            .filter { $0.itemName == itemName }
            .sorted { $0.floorNumber < $1.floorNumber }
    }
}
