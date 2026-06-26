import XCTest
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class DailyReportServiceTests: XCTestCase {
    func test_makeShareText_includesCoreReportTotalsAndItems() {
        let log = makeLog()

        let text = DailyReportService.makeShareText(from: log)

        XCTAssertTrue(text.contains("HimmerFlow Daily Report"))
        XCTAssertTrue(text.contains("Tower: Diamond"))
        XCTAssertTrue(text.contains("Floors: 15"))
        XCTAssertTrue(text.contains("Received: 55 pcs"))
        XCTAssertTrue(text.contains("Required: 60 pcs"))
        XCTAssertTrue(text.contains("Net: -5 pcs"))
        XCTAssertTrue(text.contains("King Sheet [OVER]: 10 bdl (5/bdl), 0 loose, deliver 10 bdl, net +5 pcs"))
    }

    func test_makeShareText_includesGroupedFloorPlanAndReceivingNotes() {
        let log = makeLog()

        let text = DailyReportService.makeShareText(from: log)

        XCTAssertTrue(text.contains("Floor Plan"))
        XCTAssertTrue(text.contains("Floors 1-15: 1 bundle"))
        XCTAssertTrue(text.contains("Receiving"))
        XCTAssertTrue(text.contains("Cart 7045"))
        XCTAssertTrue(text.contains("Notes"))
        XCTAssertTrue(text.contains("Recovered shortage after floor check."))
    }

    private func makeLog() -> DailyLog {
        DailyLog(
            date: Date(timeIntervalSince1970: 1_800_000_000),
            towerName: "Diamond",
            floorCount: 15,
            entriesSnapshot: [
                ReceivingEntry(
                    itemName: "King Sheet",
                    countMethod: .cartLabelPieces,
                    manualPieces: 50,
                    calculatedPieces: 50,
                    calculatedFullBundles: 10,
                    loosePieces: 0,
                    notes: "Cart 7045"
                ),
                ReceivingEntry(
                    itemName: "Bath Towel",
                    countMethod: .fixedBin,
                    binCount: 1,
                    piecesPerBin: 245,
                    calculatedPieces: 5,
                    calculatedFullBundles: 1,
                    loosePieces: 0
                )
            ],
            summarySnapshot: [
                CalculationSummary(
                    itemName: "King Sheet",
                    receivedPieces: 50,
                    bundleSize: 5,
                    fullBundles: 10,
                    loosePieces: 0,
                    requiredPieces: 45,
                    requiredBundles: 45,
                    maxAllowedBundles: 45,
                    deliverableBundles: 10,
                    shortageBundles: 35,
                    leftoverBundles: 0,
                    differencePieces: 5,
                    differenceBundles: -35,
                    status: .overage,
                    exactPerFloorPieces: 3,
                    basePerFloorPieces: 3,
                    remainderPieces: 0
                ),
                CalculationSummary(
                    itemName: "Bath Towel",
                    receivedPieces: 5,
                    bundleSize: 5,
                    fullBundles: 1,
                    loosePieces: 0,
                    requiredPieces: 15,
                    requiredBundles: 15,
                    maxAllowedBundles: 15,
                    deliverableBundles: 1,
                    shortageBundles: 14,
                    leftoverBundles: 0,
                    differencePieces: -10,
                    differenceBundles: -14,
                    status: .shortage,
                    exactPerFloorPieces: 1,
                    basePerFloorPieces: 0,
                    remainderPieces: 5
                )
            ],
            distributionSnapshot: (1...15).map {
                FloorDistributionRow(
                    floorNumber: $0,
                    itemName: "King Sheet",
                    suggestedPieces: 0,
                    suggestedBundles: 1
                )
            },
            notes: "Recovered shortage after floor check.",
            createdAt: Date(timeIntervalSince1970: 1_800_000_100)
        )
    }
}
