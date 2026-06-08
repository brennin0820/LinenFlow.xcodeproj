import XCTest
@testable import HimmerFlow

final class CalculatorTests: XCTestCase {

    // MARK: - BundleLibrary

    func test_bundleLibrary_defaultSeedValues() {
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Bath Towel"), 5)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Bath Mat"), 10)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Hand Towel"), 20)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Washcloth"), 50)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Pillow Case"), 50)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "King Sheet"), 5)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "King Cover"), 5)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Queen Sheet"), 5)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Queen Cover"), 5)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Double Sheet"), 5)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Double Cover"), 5)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Twin Sheet"), 5)
        XCTAssertEqual(BundleLibrary.bundleSize(for: "Twin Cover"), 5)
    }

    func test_bundleLibrary_aliasResolution() {
        XCTAssertEqual(BundleLibrary.canonicalName(for: "Double Duvet"), "Double Cover")
        XCTAssertEqual(BundleLibrary.canonicalName(for: "King Duvet"), "King Cover")
        XCTAssertEqual(BundleLibrary.canonicalName(for: "King Duvet / King Cover"), "King Cover")
        XCTAssertEqual(BundleLibrary.canonicalName(for: "Pillowcase"), "Pillow Case")
        XCTAssertEqual(BundleLibrary.canonicalName(for: "Wash Cloth"), "Washcloth")
        XCTAssertEqual(BundleLibrary.canonicalName(for: "TS"), "Twin Sheet")
        XCTAssertEqual(BundleLibrary.canonicalName(for: "TC"), "Twin Cover")
    }

    // MARK: - Bath Towel 2 bins (bundle-par semantics)

    func test_bathTowelTwoBins_bundleParRequiredPieces() {
        let entry = ReceivingEntry(
            itemName: "Bath Towel",
            countMethod: .fixedBin,
            binCount: 2,
            piecesPerBin: 245
        )
        let received = LinenCalculatorService.calculateReceivedPieces(entry: entry)
        XCTAssertEqual(received, 490)

        let summary = LinenCalculatorService.calculateSummary(
            itemName: "Bath Towel",
            receivedPieces: received,
            floorCount: 21,
            parCount: 14,
            bundleSize: 5
        )
        XCTAssertEqual(summary.requiredBundles, 294)
        XCTAssertEqual(summary.requiredPieces, 1470)
        XCTAssertEqual(summary.differencePieces, -980)
        XCTAssertEqual(summary.differenceBundles, -196)
        XCTAssertEqual(summary.status, .shortage)
        XCTAssertEqual(summary.shortageBundles, 196)
        XCTAssertEqual(summary.deliverableBundles, 98)
        XCTAssertEqual(summary.fullBundles, 98)
        XCTAssertEqual(summary.loosePieces, 0)
        XCTAssertEqual(summary.basePerFloorPieces, 23)
        XCTAssertEqual(summary.remainderPieces, 7)
    }

    // MARK: - Manual shortage / exact / overage (bundle-par)

    func test_manualShortage_bundlePar() {
        let summary = LinenCalculatorService.calculateSummary(
            itemName: "Bath Mat",
            receivedPieces: 60,
            floorCount: 21,
            parCount: 3,
            bundleSize: 10
        )
        XCTAssertEqual(summary.requiredBundles, 63)
        XCTAssertEqual(summary.requiredPieces, 630)
        XCTAssertEqual(summary.differencePieces, -570)
        XCTAssertEqual(summary.differenceBundles, -57)
        XCTAssertEqual(summary.status, .shortage)
        XCTAssertEqual(summary.shortageBundles, 57)
    }

    func test_exactMatch_bundlePar() {
        let summary = LinenCalculatorService.calculateSummary(
            itemName: "Bath Mat",
            receivedPieces: 630,
            floorCount: 21,
            parCount: 3,
            bundleSize: 10
        )
        XCTAssertEqual(summary.differencePieces, 0)
        XCTAssertEqual(summary.differenceBundles, 0)
        XCTAssertEqual(summary.status, .exact)
    }

    func test_overage_bundlePar() {
        let summary = LinenCalculatorService.calculateSummary(
            itemName: "Hand Towel",
            receivedPieces: 100,
            floorCount: 21,
            parCount: 4,
            bundleSize: 20
        )
        XCTAssertEqual(summary.requiredBundles, 84)
        XCTAssertEqual(summary.requiredPieces, 1680)
        XCTAssertEqual(summary.differencePieces, -1580)
        XCTAssertEqual(summary.status, .shortage)
    }

    func test_bundleParSummary_alignsWithDeliveryPlan() {
        let summary = LinenCalculatorService.calculateSummary(
            itemName: "Twin Sheet",
            receivedPieces: 50,
            floorCount: 15,
            parCount: 4,
            bundleSize: 5
        )
        XCTAssertEqual(summary.requiredBundles, 60)
        XCTAssertEqual(summary.requiredPieces, 300)
        XCTAssertEqual(summary.maxAllowedBundles, 60)
        XCTAssertEqual(summary.deliverableBundles, 10)
        XCTAssertEqual(summary.shortageBundles, 50)
        XCTAssertEqual(summary.differenceBundles, -50)
        XCTAssertEqual(summary.differencePieces, -250)
        XCTAssertEqual(summary.status, .shortage)
    }

    func test_requiredBundles_consistencyWithTowerParRequirement() {
        let floorCount = 15
        let parCount = 4
        let bundleSize = 5
        let summary = LinenCalculatorService.calculateSummary(
            itemName: "Twin Sheet",
            receivedPieces: 300,
            floorCount: floorCount,
            parCount: parCount,
            bundleSize: bundleSize
        )
        let expectedRequiredBundles = LinenCalculatorService.calculateRequiredBundles(
            floorCount: floorCount,
            parCount: parCount
        )
        XCTAssertEqual(summary.requiredBundles, expectedRequiredBundles)
        XCTAssertEqual(expectedRequiredBundles * bundleSize, summary.requiredPieces)
    }

    func test_differenceBundles_usesCeilForPieceParShortages() {
        let summary = LinenCalculatorService.calculateSummary(
            itemName: "Bath Mat",
            receivedPieces: 60,
            floorCount: 21,
            parCount: 3,
            bundleSize: 10,
            parCountsBundles: false
        )
        XCTAssertEqual(summary.requiredPieces, 63)
        XCTAssertEqual(summary.requiredBundles, 7)
        XCTAssertEqual(summary.differencePieces, -3)
        XCTAssertEqual(summary.differenceBundles, -1)
    }

    func test_noParSummary_usesReceivedPiecesAsDistributionTruth() {
        let summary = LinenCalculatorService.calculateNoParSummary(
            itemName: "Bath Mat",
            receivedPieces: 60,
            floorCount: 21,
            bundleSize: 10
        )

        XCTAssertEqual(summary.requiredPieces, 60)
        XCTAssertEqual(summary.differencePieces, 0)
        XCTAssertEqual(summary.status, .exact)
        XCTAssertEqual(summary.shortageBundles, 0)
        XCTAssertEqual(summary.leftoverBundles, 0)
        XCTAssertEqual(summary.basePerFloorPieces, 2)
        XCTAssertEqual(summary.remainderPieces, 18)
    }

    // MARK: - Remainder distribution

    func test_remainderDistribution() {
        let rows = LinenCalculatorService.calculateFloorDistribution(
            receivedPieces: 490,
            floorCount: 21,
            itemName: "Bath Towel"
        )
        XCTAssertEqual(rows.count, 21)
        // first 7 get 24, rest get 23
        for floor in 1...7 {
            XCTAssertEqual(rows[floor - 1].suggestedPieces, 24, "floor \(floor) should get 24")
        }
        for floor in 8...21 {
            XCTAssertEqual(rows[floor - 1].suggestedPieces, 23, "floor \(floor) should get 23")
        }
    }

    // MARK: - Bundle conversion for every item

    func test_bundleConversion_everyItem() {
        let cases: [(name: String, pieces: Int, bundle: Int, full: Int, loose: Int)] = [
            ("Bath Towel", 490, 5, 98, 0),
            ("Bath Mat", 35, 10, 3, 5),
            ("Hand Towel", 100, 20, 5, 0),
            ("Washcloth", 175, 50, 3, 25),
            ("Pillow Case", 200, 50, 4, 0),
            ("King Sheet", 50, 5, 10, 0),
            ("King Cover", 50, 5, 10, 0),
            ("Queen Sheet", 27, 5, 5, 2),
            ("Queen Cover", 33, 5, 6, 3),
            ("Double Sheet", 89, 5, 17, 4),
            ("Double Cover", 116, 5, 23, 1),
            ("Twin Sheet", 50, 5, 10, 0),
            ("Twin Cover", 52, 5, 10, 2),
        ]
        for c in cases {
            let result = LinenCalculatorService.convertPiecesToBundles(pieces: c.pieces, bundleSize: c.bundle)
            XCTAssertEqual(result.fullBundles, c.full, "\(c.name) full bundles")
            XCTAssertEqual(result.loosePieces, c.loose, "\(c.name) loose pieces")
        }
    }

    // MARK: - Tower distributions

    func test_giDistribution_32Floors() {
        let base = LinenCalculatorService.calculateBasePerFloor(receivedPieces: 245, floorCount: 32)
        let remainder = LinenCalculatorService.calculateRemainder(receivedPieces: 245, floorCount: 32)
        XCTAssertEqual(base, 7)
        XCTAssertEqual(remainder, 21)
    }

    func test_gwDistribution_32Floors() {
        let base = LinenCalculatorService.calculateBasePerFloor(receivedPieces: 245, floorCount: 32)
        let remainder = LinenCalculatorService.calculateRemainder(receivedPieces: 245, floorCount: 32)
        XCTAssertEqual(base, 7)
        XCTAssertEqual(remainder, 21)
    }

    func test_diamondDistribution_15Floors() {
        // 60 bundles across 15 floors = 4 per floor, no remainder
        let rows = LinenCalculatorService.calculateBundleFloorDistribution(
            fullBundles: 60,
            floorCount: 15,
            itemName: "Double Cover"
        )
        XCTAssertEqual(rows.count, 15)
        for row in rows {
            XCTAssertEqual(row.suggestedBundles, 4)
        }
    }

    func test_twinSheetDiamondDistribution_respectsParCap() {
        let result = LinenCalculatorService.convertPiecesToBundles(pieces: 50, bundleSize: 5)
        XCTAssertEqual(result.fullBundles, 10)
        XCTAssertEqual(result.loosePieces, 0)

        let plan = LinenCalculatorService.calculateBundleDeliveryPlan(
            fullBundles: result.fullBundles,
            floorCount: 15,
            parPerFloor: 4
        )
        XCTAssertEqual(plan.maxAllowedBundles, 60)
        XCTAssertEqual(plan.deliverableBundles, 10)
        XCTAssertEqual(plan.shortageBundles, 50)
        XCTAssertEqual(plan.leftoverBundles, 0)

        let rows = LinenCalculatorService.calculateCappedBundleFloorDistribution(
            fullBundles: result.fullBundles,
            floorCount: 15,
            parPerFloor: 4,
            itemName: "Twin Sheet"
        )
        XCTAssertEqual(rows.count, 15)
        for floor in 1...10 {
            XCTAssertEqual(rows[floor - 1].suggestedBundles, 1, "floor \(floor)")
        }
        for floor in 11...15 {
            XCTAssertEqual(rows[floor - 1].suggestedBundles, 0, "floor \(floor)")
        }
    }

    func test_twinCoverOverParStock_capsDeliveryAndLeavesLeftover() {
        let result = LinenCalculatorService.convertPiecesToBundles(pieces: 400, bundleSize: 5)
        XCTAssertEqual(result.fullBundles, 80)
        XCTAssertEqual(result.loosePieces, 0)

        let plan = LinenCalculatorService.calculateBundleDeliveryPlan(
            fullBundles: result.fullBundles,
            floorCount: 15,
            parPerFloor: 4
        )
        XCTAssertEqual(plan.maxAllowedBundles, 60)
        XCTAssertEqual(plan.deliverableBundles, 60)
        XCTAssertEqual(plan.shortageBundles, 0)
        XCTAssertEqual(plan.leftoverBundles, 20)

        let rows = LinenCalculatorService.calculateCappedBundleFloorDistribution(
            fullBundles: result.fullBundles,
            floorCount: 15,
            parPerFloor: 4,
            itemName: "Twin Cover"
        )
        XCTAssertEqual(rows.count, 15)
        for row in rows {
            XCTAssertEqual(row.suggestedBundles, 4)
        }
    }

    func test_twinSheetExactPar_hasNoShortageOrLeftover() {
        let result = LinenCalculatorService.convertPiecesToBundles(pieces: 300, bundleSize: 5)
        XCTAssertEqual(result.fullBundles, 60)
        XCTAssertEqual(result.loosePieces, 0)

        let plan = LinenCalculatorService.calculateBundleDeliveryPlan(
            fullBundles: result.fullBundles,
            floorCount: 15,
            parPerFloor: 4
        )
        XCTAssertEqual(plan.maxAllowedBundles, 60)
        XCTAssertEqual(plan.deliverableBundles, 60)
        XCTAssertEqual(plan.shortageBundles, 0)
        XCTAssertEqual(plan.leftoverBundles, 0)

        let rows = LinenCalculatorService.calculateCappedBundleFloorDistribution(
            fullBundles: result.fullBundles,
            floorCount: 15,
            parPerFloor: 4,
            itemName: "Twin Sheet"
        )
        XCTAssertEqual(rows.count, 15)
        for row in rows {
            XCTAssertEqual(row.suggestedBundles, 4)
        }
    }

    func test_aliiDistribution_14Floors() {
        // 14 floors, par 3 bundles/floor, bundle size 5 → 210 required pieces
        let summary = LinenCalculatorService.calculateSummary(
            itemName: "King Sheet",
            receivedPieces: 210,
            floorCount: 14,
            parCount: 3,
            bundleSize: 5
        )
        XCTAssertEqual(summary.requiredBundles, 42)
        XCTAssertEqual(summary.requiredPieces, 210)
        XCTAssertEqual(summary.status, .exact)
        XCTAssertEqual(summary.basePerFloorPieces, 15)
        XCTAssertEqual(summary.remainderPieces, 0)
    }

    // MARK: - Safety

    func test_zeroFloorCount_doesNotCrash() {
        let summary = LinenCalculatorService.calculateSummary(
            itemName: "Bath Towel",
            receivedPieces: 100,
            floorCount: 0,
            parCount: 14,
            bundleSize: 5
        )
        XCTAssertEqual(summary.requiredPieces, 0)
        XCTAssertEqual(summary.requiredBundles, 0)
        XCTAssertEqual(summary.basePerFloorPieces, 0)
        XCTAssertEqual(summary.remainderPieces, 0)
        XCTAssertEqual(summary.exactPerFloorPieces, 0)

        let rows = LinenCalculatorService.calculateFloorDistribution(
            receivedPieces: 100,
            floorCount: 0,
            itemName: "Bath Towel"
        )
        XCTAssertTrue(rows.isEmpty)
    }

    func test_zeroReceivedPieces_doesNotCrash() {
        let summary = LinenCalculatorService.calculateSummary(
            itemName: "Bath Towel",
            receivedPieces: 0,
            floorCount: 21,
            parCount: 14,
            bundleSize: 5
        )
        XCTAssertEqual(summary.fullBundles, 0)
        XCTAssertEqual(summary.loosePieces, 0)
        XCTAssertEqual(summary.requiredBundles, 294)
        XCTAssertEqual(summary.requiredPieces, 1470)
        XCTAssertEqual(summary.differencePieces, -1470)
        XCTAssertEqual(summary.differenceBundles, -294)
        XCTAssertEqual(summary.status, .shortage)
        XCTAssertEqual(summary.basePerFloorPieces, 0)
        XCTAssertEqual(summary.remainderPieces, 0)
    }

    // MARK: - DailyLog snapshot round-trip

    func test_dailyLog_snapshotRoundTrip() {
        let entries = [
            ReceivingEntry(itemName: "Bath Towel", countMethod: .fixedBin, binCount: 2, piecesPerBin: 245, calculatedPieces: 490, calculatedFullBundles: 98, loosePieces: 0)
        ]
        let summaries = [
            LinenCalculatorService.calculateSummary(
                itemName: "Bath Towel",
                receivedPieces: 490,
                floorCount: 21,
                parCount: 14,
                bundleSize: 5
            )
        ]
        let distribution = LinenCalculatorService.calculateFloorDistribution(receivedPieces: 490, floorCount: 21, itemName: "Bath Towel")

        let log = DailyLog(
            date: Date(),
            towerName: "Lagoon",
            floorCount: 21,
            entriesSnapshot: entries,
            summarySnapshot: summaries,
            distributionSnapshot: distribution,
            notes: "round-trip test"
        )

        XCTAssertEqual(log.entriesSnapshot.count, 1)
        XCTAssertEqual(log.entriesSnapshot.first?.calculatedPieces, 490)
        XCTAssertEqual(log.summarySnapshot.first?.differencePieces, -980)
        XCTAssertEqual(log.distributionSnapshot.count, 21)
        XCTAssertEqual(log.distributionSnapshot[0].suggestedPieces, 24)
        XCTAssertEqual(log.distributionSnapshot[20].suggestedPieces, 23)
    }
}
