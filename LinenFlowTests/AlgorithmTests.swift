import XCTest
@testable import HimmerFlow

final class AlgorithmTests: XCTestCase {

    // MARK: - ReceivingAggregationAlgorithm

    func test_aggregation_emptyEntriesReturnsEmpty() {
        let result = ReceivingAggregationAlgorithm.aggregate([])
        XCTAssertTrue(result.isEmpty)
    }

    func test_aggregation_singleEntry() {
        let entries = [
            ReceivingEntry(itemName: "King Sheet", countMethod: .manualPieces, manualPieces: 50, calculatedPieces: 50)
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].itemName, "King Sheet")
        XCTAssertEqual(result[0].totalPieces, 50)
        XCTAssertEqual(result[0].sourceEntryCount, 1)
    }

    func test_aggregation_twoEntriesSameItem_sumsPieces() {
        let entries = [
            ReceivingEntry(itemName: "Double Sheet", countMethod: .cartLabelPieces, manualPieces: 39, calculatedPieces: 39),
            ReceivingEntry(itemName: "Double Sheet", countMethod: .cartLabelPieces, manualPieces: 50, calculatedPieces: 50),
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].itemName, "Double Sheet")
        XCTAssertEqual(result[0].totalPieces, 89)
        XCTAssertEqual(result[0].sourceEntryCount, 2)
    }

    func test_aggregation_mixedItems_twoGroups() {
        let entries = [
            ReceivingEntry(itemName: "Double Sheet", countMethod: .cartLabelPieces, manualPieces: 39, calculatedPieces: 39),
            ReceivingEntry(itemName: "King Sheet",   countMethod: .cartLabelPieces, manualPieces: 50, calculatedPieces: 50),
            ReceivingEntry(itemName: "Double Sheet", countMethod: .cartLabelPieces, manualPieces: 50, calculatedPieces: 50),
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.count, 2)
        let ds = result.first { $0.itemName == "Double Sheet" }
        let ks = result.first { $0.itemName == "King Sheet" }
        XCTAssertEqual(ds?.totalPieces, 89)
        XCTAssertEqual(ds?.sourceEntryCount, 2)
        XCTAssertEqual(ks?.totalPieces, 50)
        XCTAssertEqual(ks?.sourceEntryCount, 1)
    }

    func test_aggregation_aliasResolvedToCanonical() {
        // "Double Duvet" is an alias for "Double Cover"
        let entries = [
            ReceivingEntry(itemName: "Double Duvet", countMethod: .cartLabelPieces, manualPieces: 51, calculatedPieces: 51),
            ReceivingEntry(itemName: "Double Cover", countMethod: .cartLabelPieces, manualPieces: 65, calculatedPieces: 65),
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].itemName, "Double Cover")
        XCTAssertEqual(result[0].totalPieces, 116)
        XCTAssertEqual(result[0].sourceEntryCount, 2)
    }

    func test_aggregation_emptyNameIgnored() {
        let entries = [
            ReceivingEntry(itemName: "",           countMethod: .manualPieces, manualPieces: 99, calculatedPieces: 99),
            ReceivingEntry(itemName: "Bath Towel", countMethod: .manualPieces, manualPieces: 490, calculatedPieces: 490),
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].itemName, "Bath Towel")
    }

    func test_aggregation_sortedAlphabetically() {
        let entries = [
            ReceivingEntry(itemName: "Washcloth",  countMethod: .manualPieces, manualPieces: 100, calculatedPieces: 100),
            ReceivingEntry(itemName: "Bath Towel", countMethod: .manualPieces, manualPieces: 490, calculatedPieces: 490),
            ReceivingEntry(itemName: "Hand Towel", countMethod: .manualPieces, manualPieces: 100, calculatedPieces: 100),
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.map(\.itemName), ["Bath Towel", "Hand Towel", "Washcloth"])
    }

    // MARK: - Diamond ALSCO aggregation (6 raw cart rows → 4 canonical items)

    func test_aggregation_diamondALSCO_sixRows_fourItems() {
        let entries = [
            ReceivingEntry(itemName: "Double Duvet",            countMethod: .cartLabelPieces, manualPieces: 51, calculatedPieces: 51),  // → DC
            ReceivingEntry(itemName: "Double Sheet",            countMethod: .cartLabelPieces, manualPieces: 39, calculatedPieces: 39),  // → DS
            ReceivingEntry(itemName: "King Sheet",              countMethod: .cartLabelPieces, manualPieces: 50, calculatedPieces: 50),  // → KS
            ReceivingEntry(itemName: "King Duvet / King Cover", countMethod: .cartLabelPieces, manualPieces: 50, calculatedPieces: 50),  // → KC
            ReceivingEntry(itemName: "Double Sheet",            countMethod: .cartLabelPieces, manualPieces: 50, calculatedPieces: 50),  // → DS
            ReceivingEntry(itemName: "Double Duvet",            countMethod: .cartLabelPieces, manualPieces: 65, calculatedPieces: 65),  // → DC
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.count, 4, "Should collapse 6 rows to 4 canonical items")

        let dc = result.first { $0.itemName == "Double Cover" }
        let ds = result.first { $0.itemName == "Double Sheet" }
        let kc = result.first { $0.itemName == "King Cover" }
        let ks = result.first { $0.itemName == "King Sheet" }

        XCTAssertEqual(dc?.totalPieces, 116, "DC: 51 + 65 = 116")
        XCTAssertEqual(dc?.sourceEntryCount, 2)
        XCTAssertEqual(ds?.totalPieces, 89, "DS: 39 + 50 = 89")
        XCTAssertEqual(ds?.sourceEntryCount, 2)
        XCTAssertEqual(ks?.totalPieces, 50)
        XCTAssertEqual(ks?.sourceEntryCount, 1)
        XCTAssertEqual(kc?.totalPieces, 50)
        XCTAssertEqual(kc?.sourceEntryCount, 1)

        let totalPcs = result.reduce(0) { $0 + $1.totalPieces }
        XCTAssertEqual(totalPcs, 305, "Total: 116 + 89 + 50 + 50 = 305")
    }

    // MARK: - BundleDistributionAlgorithm

    func test_bundleConversion_lockedBundleSizes() {
        let cases: [(name: String, pieces: Int, expectedFull: Int, expectedLoose: Int)] = [
            ("Bath Towel",   245, 49, 0),
            ("Bath Mat",      63,  6, 3),
            ("Hand Towel",   100,  5, 0),
            ("Washcloth",    101,  2, 1),
            ("Pillow Case",   99,  1, 49),
            ("Double Sheet",  89, 17, 4),
            ("Double Cover", 116, 23, 1),
        ]
        for c in cases {
            let bundleSize = BundleLibrary.bundleSize(for: c.name) ?? 0
            let result = BundleDistributionAlgorithm.convertPiecesToBundles(pieces: c.pieces, bundleSize: bundleSize)
            XCTAssertEqual(result.fullBundles, c.expectedFull, "\(c.name) full bundles from \(c.pieces) pcs")
            XCTAssertEqual(result.loosePieces, c.expectedLoose, "\(c.name) loose pcs from \(c.pieces) pcs")
        }
    }

    func test_bundleConversion_zeroBundleSize_returnsAllLoose() {
        let result = BundleDistributionAlgorithm.convertPiecesToBundles(pieces: 100, bundleSize: 0)
        XCTAssertEqual(result.fullBundles, 0)
        XCTAssertEqual(result.loosePieces, 100)
    }

    func test_bundleConversion_negativepieces_clampsToZero() {
        let result = BundleDistributionAlgorithm.convertPiecesToBundles(pieces: -10, bundleSize: 5)
        XCTAssertEqual(result.fullBundles, 0)
        XCTAssertEqual(result.loosePieces, 0)
    }

    func test_distributeBundles_diamond60Bundles15Floors() {
        let rows = BundleDistributionAlgorithm.distributeBundles(fullBundles: 60, floorCount: 15, itemName: "Double Cover")
        XCTAssertEqual(rows.count, 15)
        for row in rows {
            XCTAssertEqual(row.suggestedBundles, 4, "Floor \(row.floorNumber) should get 4 bundles")
        }
    }

    func test_distributeBundlesWithParCap_shortfall() {
        // 10 bundles available, par 4/floor, 15 floors → shortage 50
        let result = BundleDistributionAlgorithm.distributeBundlesWithParCap(
            fullBundles: 10,
            floorCount: 15,
            parPerFloor: 4,
            itemName: "Twin Sheet"
        )
        XCTAssertEqual(result.deliverableBundles, 10)
        XCTAssertEqual(result.shortageBundles, 50)
        XCTAssertEqual(result.leftoverBundles, 0)
        XCTAssertEqual(result.rows.count, 15)
        // 10 bundles across 15 floors: first 10 get 1, last 5 get 0
        let nonZero = result.rows.filter { ($0.suggestedBundles ?? 0) > 0 }
        XCTAssertEqual(nonZero.count, 10)
    }

    func test_distributeBundlesWithParCap_zeroBundles_allZeroRows() {
        let result = BundleDistributionAlgorithm.distributeBundlesWithParCap(
            fullBundles: 0,
            floorCount: 15,
            parPerFloor: 4,
            itemName: "Bath Towel"
        )
        XCTAssertEqual(result.deliverableBundles, 0)
        XCTAssertEqual(result.shortageBundles, 60)
        XCTAssertEqual(result.rows.count, 15)
        for row in result.rows {
            XCTAssertEqual(row.suggestedBundles ?? 0, 0)
        }
    }

    func test_distributeBundlesWithParCap_zeroFloors_returnsEmpty() {
        let result = BundleDistributionAlgorithm.distributeBundlesWithParCap(
            fullBundles: 50,
            floorCount: 0,
            parPerFloor: 4,
            itemName: "Bath Towel"
        )
        XCTAssertTrue(result.rows.isEmpty)
    }

    // MARK: - DeliverySessionProgressAlgorithm

    func test_progress_empty_isZeroFraction() {
        let frac = DeliverySessionProgressAlgorithm.progressFraction(floorCount: 15, completedFloorNumbers: [])
        XCTAssertEqual(frac, 0)
    }

    func test_progress_allComplete_isFractionOne() {
        let all = Set(1...15)
        let frac = DeliverySessionProgressAlgorithm.progressFraction(floorCount: 15, completedFloorNumbers: all)
        XCTAssertEqual(frac, 1.0, accuracy: 0.001)
    }

    func test_progress_halfComplete() {
        let half = Set(1...8)
        let frac = DeliverySessionProgressAlgorithm.progressFraction(floorCount: 15, completedFloorNumbers: half)
        XCTAssertEqual(frac, 8.0 / 15.0, accuracy: 0.001)
        XCTAssertEqual(DeliverySessionProgressAlgorithm.remainingCount(floorCount: 15, completedFloorNumbers: half), 7)
    }

    func test_progress_zeroFloorCount_isZeroFraction() {
        let frac = DeliverySessionProgressAlgorithm.progressFraction(floorCount: 0, completedFloorNumbers: [1, 2])
        XCTAssertEqual(frac, 0)
    }

    func test_progress_isComplete_trueWhenAllDone() {
        let all = Set(1...15)
        XCTAssertTrue(DeliverySessionProgressAlgorithm.isComplete(floorCount: 15, completedFloorNumbers: all))
    }

    func test_progress_isComplete_falseWhenPartial() {
        XCTAssertFalse(DeliverySessionProgressAlgorithm.isComplete(floorCount: 15, completedFloorNumbers: [1, 2]))
    }

    func test_progress_isComplete_falseWhenZeroFloors() {
        XCTAssertFalse(DeliverySessionProgressAlgorithm.isComplete(floorCount: 0, completedFloorNumbers: []))
    }

    func test_progress_remainingNeverNegative() {
        // More completed than floor count
        let over = Set(1...20)
        let remaining = DeliverySessionProgressAlgorithm.remainingCount(floorCount: 15, completedFloorNumbers: over)
        XCTAssertEqual(remaining, 0)
    }

    // MARK: - WidgetFloorPlanAlgorithm

    func test_widgetFloorPlan_emptyDistributions_returnsEmpty() {
        let rows = WidgetFloorPlanAlgorithm.buildRows(
            distributions: [],
            itemName: "Bath Towel",
            unitIsBundles: false
        )
        XCTAssertTrue(rows.isEmpty)
    }

    func test_widgetFloorPlan_evenDistribution_singleRow() {
        // 60 bundles across 15 floors = 4 per floor, no remainder → 1 merged row
        let distributions = LinenCalculatorService.calculateBundleFloorDistribution(
            fullBundles: 60,
            floorCount: 15,
            itemName: "Double Cover"
        )
        let rows = WidgetFloorPlanAlgorithm.buildRows(
            distributions: distributions,
            itemName: "Double Cover",
            unitIsBundles: true
        )
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].valueText, "4 bdl")
        XCTAssertFalse(rows[0].isPriority)
    }

    func test_widgetFloorPlan_unevenDistribution_twoRows() {
        // 490 pcs across 21 floors: first 7 get 24, rest 23 → 2 ranges → 2 merged rows
        let distributions = LinenCalculatorService.calculateFloorDistribution(
            receivedPieces: 490,
            floorCount: 21,
            itemName: "Bath Towel"
        )
        let rows = WidgetFloorPlanAlgorithm.buildRows(
            distributions: distributions,
            itemName: "Bath Towel",
            unitIsBundles: false
        )
        XCTAssertEqual(rows.count, 2)
        let priorityRow = rows.first { $0.isPriority }
        let normalRow = rows.first { !$0.isPriority }
        XCTAssertEqual(priorityRow?.valueText, "24 pcs")
        XCTAssertEqual(normalRow?.valueText, "23 pcs")
        XCTAssertEqual(priorityRow?.floorCount, 7)
        XCTAssertEqual(normalRow?.floorCount, 14)
    }

    func test_widgetFloorPlan_maxRowsCapped() {
        // Force many ranges by crafting artificial rows: 10 distinct values
        var dists: [FloorDistributionRow] = []
        for floor in 1...10 {
            dists.append(FloorDistributionRow(floorNumber: floor, itemName: "X", suggestedPieces: floor * 10))
        }
        let rows = WidgetFloorPlanAlgorithm.buildRows(
            distributions: dists,
            itemName: "X",
            unitIsBundles: false,
            maxRows: 4
        )
        XCTAssertLessThanOrEqual(rows.count, 4)
    }

    // MARK: - Floor sequence locked rules

    func test_floorSequences_lockedCounts() {
        XCTAssertEqual(DeliveryFloorSequenceService.deliveryFloors(towerName: "Diamond",          floorCount: 15).count, 15)
        XCTAssertEqual(DeliveryFloorSequenceService.deliveryFloors(towerName: "Alii",             floorCount: 14).count, 14)
        XCTAssertEqual(DeliveryFloorSequenceService.deliveryFloors(towerName: "Tapa",             floorCount: 33).count, 33)
        XCTAssertEqual(DeliveryFloorSequenceService.deliveryFloors(towerName: "GW",               floorCount: 32).count, 32)
        XCTAssertEqual(DeliveryFloorSequenceService.deliveryFloors(towerName: "Grand Waikikian",  floorCount: 32).count, 32)
    }

    func test_gwFloors_excludesForbiddenFloors() {
        let floors = DeliveryFloorSequenceService.deliveryFloors(towerName: "GW", floorCount: 32)
        XCTAssertFalse(floors.contains(13), "GW must skip floor 13")
        XCTAssertFalse(floors.contains(33), "GW must skip floor 33")
        XCTAssertFalse(floors.contains(34), "GW must skip floor 34")
    }

    func test_gwFloors_exactSequence() {
        let expected = Array(5...12) + Array(14...32) + Array(35...39)
        XCTAssertEqual(expected.count, 32)
        let actual = DeliveryFloorSequenceService.deliveryFloors(towerName: "GW", floorCount: 32)
        XCTAssertEqual(actual, expected)
    }

    func test_tapaFloors_startAt3EndAt35() {
        let floors = DeliveryFloorSequenceService.deliveryFloors(towerName: "Tapa", floorCount: 33)
        XCTAssertEqual(floors.first, 3)
        XCTAssertEqual(floors.last, 35)
    }

    // MARK: - Zero / boundary safety

    func test_bundleConversion_zeroPieces_zerosOut() {
        let r = BundleDistributionAlgorithm.convertPiecesToBundles(pieces: 0, bundleSize: 5)
        XCTAssertEqual(r.fullBundles, 0)
        XCTAssertEqual(r.loosePieces, 0)
    }

    func test_aggregation_zeroCalculatedPieces_stillAggregates() {
        let entries = [
            ReceivingEntry(itemName: "Bath Towel", countMethod: .manualPieces, manualPieces: 0, calculatedPieces: 0)
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].totalPieces, 0)
    }

    func test_aggregation_legacySnapshotFallsBackToCalculatedPieces() {
        let entries = [
            ReceivingEntry(itemName: "King Sheet", countMethod: .manualPieces, calculatedPieces: 50)
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].totalPieces, 50)
    }

    func test_aggregation_recomputesPiecesFromCountMethod_notStaleCalculatedPieces() {
        let entries = [
            ReceivingEntry(
                itemName: "Bath Towel",
                countMethod: .fixedBin,
                binCount: 2,
                piecesPerBin: 245,
                calculatedPieces: 999
            ),
            ReceivingEntry(
                itemName: "Bath Towel",
                countMethod: .manualPieces,
                manualPieces: 50,
                calculatedPieces: 1
            ),
        ]
        let result = ReceivingAggregationAlgorithm.aggregate(entries)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].totalPieces, 540, "Should sum 490 + 50 from count method, ignoring stale calculatedPieces")
        XCTAssertEqual(result[0].sourceEntryCount, 2)
    }

    func test_progress_completedCount_correctForAnySet() {
        XCTAssertEqual(DeliverySessionProgressAlgorithm.completedCount([]), 0)
        XCTAssertEqual(DeliverySessionProgressAlgorithm.completedCount([5, 7, 12]), 3)
        XCTAssertEqual(DeliverySessionProgressAlgorithm.completedCount(Set(1...15)), 15)
    }

    // MARK: - TimeshareReserveAlgorithm

    func test_timeshareReserve_exactAtZero() {
        let result = TimeshareReserveAlgorithm.evaluate(reservePieces: 0)
        XCTAssertEqual(result.reservePieces, 0)
        XCTAssertEqual(result.status, .exact)
    }

    func test_timeshareReserve_lowReserveFromOneThroughNineteen() {
        XCTAssertEqual(TimeshareReserveAlgorithm.status(for: 1), .lowReserve)
        XCTAssertEqual(TimeshareReserveAlgorithm.status(for: 19), .lowReserve)
    }

    func test_timeshareReserve_idealMorningReserveFromTwentyThroughTwentyFive() {
        XCTAssertEqual(TimeshareReserveAlgorithm.status(for: 20), .idealMorningReserve)
        XCTAssertEqual(TimeshareReserveAlgorithm.status(for: 25), .idealMorningReserve)
    }

    func test_timeshareReserve_overReserveAboveTwentyFive() {
        XCTAssertEqual(TimeshareReserveAlgorithm.status(for: 26), .overReserve)
    }

    func test_timeshareReserve_negativeValuesClampToExact() {
        let result = TimeshareReserveAlgorithm.evaluate(reservePieces: -4)
        XCTAssertEqual(result.reservePieces, 0)
        XCTAssertEqual(result.status, .exact)
    }
}
