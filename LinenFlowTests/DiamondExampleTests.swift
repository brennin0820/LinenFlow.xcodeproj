import XCTest
import SwiftData
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

@MainActor
final class DiamondExampleTests: XCTestCase {

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
        viewModel.loadDiamondDHeadExample()
    }

    override func tearDownWithError() throws {
        viewModel = nil
        container = nil
    }

    // MARK: - Cart preservation

    func test_rawCartRowsPreservedInEntries() {
        XCTAssertEqual(viewModel.receivingEntries.count, 6, "expected 6 raw cart rows (3 carts × 2 items each)")
        let cartNotes = Set(viewModel.receivingEntries.compactMap(\.notes))
        XCTAssertTrue(cartNotes.contains("Cart 1801"))
        XCTAssertTrue(cartNotes.contains("Cart 7045"))
        XCTAssertTrue(cartNotes.contains("Cart 1406"))
    }

    func test_combinedTotals() {
        XCTAssertEqual(viewModel.calculationSummaries.count, 4, "Double Cover, Double Sheet, King Sheet, King Cover")
        let total = viewModel.calculationSummaries.reduce(0) { $0 + $1.receivedPieces }
        XCTAssertEqual(total, 305)
    }

    func test_bundleTotal_60_loose5() {
        let totalBundles = viewModel.calculationSummaries.reduce(0) { $0 + $1.fullBundles }
        let totalLoose = viewModel.calculationSummaries.reduce(0) { $0 + $1.loosePieces }
        XCTAssertEqual(totalBundles, 60)
        XCTAssertEqual(totalLoose, 5)
    }

    // MARK: - Per-item bundle conversion

    func test_doubleCover_23bundles_1loose() {
        let s = summary(for: "Double Cover")
        XCTAssertEqual(s?.receivedPieces, 116)
        XCTAssertEqual(s?.fullBundles, 23)
        XCTAssertEqual(s?.loosePieces, 1)
    }

    func test_doubleSheet_17bundles_4loose() {
        let s = summary(for: "Double Sheet")
        XCTAssertEqual(s?.receivedPieces, 89)
        XCTAssertEqual(s?.fullBundles, 17)
        XCTAssertEqual(s?.loosePieces, 4)
    }

    func test_kingSheet_10bundles_0loose() {
        let s = summary(for: "King Sheet")
        XCTAssertEqual(s?.receivedPieces, 50)
        XCTAssertEqual(s?.fullBundles, 10)
        XCTAssertEqual(s?.loosePieces, 0)
    }

    func test_kingCover_10bundles_0loose() {
        let s = summary(for: "King Cover")
        XCTAssertEqual(s?.receivedPieces, 50)
        XCTAssertEqual(s?.fullBundles, 10)
        XCTAssertEqual(s?.loosePieces, 0)
    }

    // MARK: - Bundle-first floor distribution

    func test_prefersBundleDelivery_forDiamond() {
        XCTAssertTrue(viewModel.prefersBundleDelivery)
    }

    func test_bundleDistribution_isPopulated() {
        XCTAssertFalse(viewModel.bundleFloorDistributions.isEmpty)
    }

    func test_kingSheet_bundleDistribution_floors1to10getOneBundle() {
        // 10 bundles across 15 floors: base 0, remainder 10 → floors 1-10 get 1, 11-15 get 0
        let rows = bundleRows(for: "King Sheet")
        XCTAssertEqual(rows.count, 15)
        for floor in 1...10 {
            XCTAssertEqual(rows[floor - 1].suggestedBundles, 1, "King Sheet floor \(floor) should get 1 bundle")
        }
        for floor in 11...15 {
            XCTAssertEqual(rows[floor - 1].suggestedBundles, 0, "King Sheet floor \(floor) should get 0 bundles")
        }
    }

    func test_doubleCover_bundleDistribution_floors1to8get2_rest1() {
        // 23 bundles across 15 floors: base 1, remainder 8 → floors 1-8 get 2, 9-15 get 1
        let rows = bundleRows(for: "Double Cover")
        XCTAssertEqual(rows.count, 15)
        for floor in 1...8 {
            XCTAssertEqual(rows[floor - 1].suggestedBundles, 2)
        }
        for floor in 9...15 {
            XCTAssertEqual(rows[floor - 1].suggestedBundles, 1)
        }
    }

    // MARK: - Save log uses bundle distribution

    func test_savedLog_usesBundleDistributionForDiamond() {
        let log = viewModel.buildDailyLog()
        XCTAssertNotNil(log)
        let snap = log?.distributionSnapshot ?? []
        let kingSheetFloor1 = snap.first { $0.itemName == "King Sheet" && $0.floorNumber == 1 }
        XCTAssertEqual(kingSheetFloor1?.suggestedBundles, 1)
        XCTAssertEqual(kingSheetFloor1?.suggestedPieces, 0)
    }

    // MARK: - Helpers

    private func summary(for itemName: String) -> CalculationSummary? {
        viewModel.calculationSummaries.first { $0.itemName == itemName }
    }

    private func bundleRows(for itemName: String) -> [FloorDistributionRow] {
        viewModel.bundleFloorDistributions
            .filter { $0.itemName == itemName }
            .sorted { $0.floorNumber < $1.floorNumber }
    }
}
