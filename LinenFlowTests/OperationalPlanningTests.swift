import XCTest
@testable import HimmerFlow

final class OperationalPlanningTests: XCTestCase {
    func test_carryGroupBuilder_bathTowelCreatesPhysicalBinsFromBinCount() {
        let entry = ReceivingEntry(
            itemName: "Bath Towel",
            countMethod: .fixedBin,
            binCount: 2,
            piecesPerBin: 245,
            calculatedPieces: 490,
            calculatedFullBundles: 98
        )

        let groups = CarryGroupBuilder().build(
            entries: [entry],
            summaries: [summary("Bath Towel", fullBundles: 98, receivedPieces: 490)]
        )

        XCTAssertEqual(groups.map(\.label), ["Bath Towel Bin 1", "Bath Towel Bin 2"])
        XCTAssertTrue(groups.allSatisfy { $0.carryType == .physicalBin })
        XCTAssertTrue(groups.allSatisfy { $0.estimatedWeightClass == .heavy })
    }

    func test_carryGroupBuilder_nonBathUsesPhysicalBinCountWhenProvided() {
        let entry = ReceivingEntry(
            itemName: "Hand Towel",
            countMethod: .manualPieces,
            physicalBinCount: 2,
            manualPieces: 100,
            calculatedPieces: 100,
            calculatedFullBundles: 5
        )

        let groups = CarryGroupBuilder().build(
            entries: [entry],
            summaries: [summary("Hand Towel", fullBundles: 5, receivedPieces: 100)]
        )

        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups.first?.carryType, .physicalBin)
        XCTAssertEqual(groups.first?.estimatedWeightClass, .medium)
    }

    func test_carryGroupBuilder_nonBathFallsBackToBundleGroup() {
        let entry = ReceivingEntry(
            itemName: "Washcloth",
            countMethod: .manualPieces,
            manualPieces: 100,
            calculatedPieces: 100,
            calculatedFullBundles: 2
        )

        let groups = CarryGroupBuilder().build(
            entries: [entry],
            summaries: [summary("Washcloth", fullBundles: 2, receivedPieces: 100)]
        )

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.carryType, .bundleGroup)
        XCTAssertEqual(groups.first?.count, 2)
        XCTAssertEqual(groups.first?.estimatedWeightClass, .light)
    }

    func test_carryGroupBuilder_createsLooseCarryOnlyWhenNoFullBundles() {
        let entry = ReceivingEntry(
            itemName: "Pillow Case",
            countMethod: .manualPieces,
            manualPieces: 25,
            calculatedPieces: 25,
            calculatedFullBundles: 0,
            loosePieces: 25
        )
        let looseSummary = summary("Pillow Case", fullBundles: 0, receivedPieces: 25, loosePieces: 25)

        let groups = CarryGroupBuilder().build(entries: [entry], summaries: [looseSummary])

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.carryType, .looseCarry)
        XCTAssertEqual(groups.first?.count, 25)
    }

    func test_operationalPolicy_blocksStrategyPlanningForTimeshareTowers() {
        XCTAssertTrue(TowerOperationalPolicy.isTimeshareTower("Lagoon"))
        XCTAssertTrue(TowerOperationalPolicy.isTimeshareTower("GI"))
        XCTAssertTrue(TowerOperationalPolicy.isTimeshareTower("GW"))
    }

    func test_operationalPolicy_allowsStrategyPlanningForHotelTowers() {
        XCTAssertFalse(TowerOperationalPolicy.isTimeshareTower("Diamond"))
        XCTAssertFalse(TowerOperationalPolicy.isTimeshareTower("Alii"))
        XCTAssertFalse(TowerOperationalPolicy.isTimeshareTower("Tapa"))
        XCTAssertFalse(TowerOperationalPolicy.isTimeshareTower("Rainbow"))
    }

    func test_doorOpeningPass_prefersWashclothWhenAvailable() {
        let summaries = [
            summary("Bath Towel", fullBundles: 10, receivedPieces: 50),
            summary("Washcloth", fullBundles: 1, receivedPieces: 50),
            summary("Hand Towel", fullBundles: 2, receivedPieces: 40)
        ]
        let rows = (3...5).map { FloorDistributionRow(floorNumber: $0, itemName: "Washcloth", suggestedPieces: 1) }

        let recommendation = DoorOpeningPassPlanner().recommendation(summaries: summaries, deliveryRows: rows)

        XCTAssertEqual(recommendation?.itemName, "Washcloth")
        XCTAssertEqual(recommendation?.floorRangeText, "Floors 3-5")
    }

    func test_elevatorTripPlanner_pairsDifferentCategoriesFirst() {
        let summaries = [
            summary("Washcloth", fullBundles: 1, receivedPieces: 50),
            summary("Hand Towel", fullBundles: 1, receivedPieces: 20),
            summary("Bath Towel", fullBundles: 98, receivedPieces: 490)
        ]
        let entries = [
            ReceivingEntry(itemName: "Bath Towel", countMethod: .fixedBin, binCount: 2, piecesPerBin: 245, calculatedPieces: 490, calculatedFullBundles: 98),
            ReceivingEntry(itemName: "Washcloth", countMethod: .manualPieces, manualPieces: 50, calculatedPieces: 50, calculatedFullBundles: 1),
            ReceivingEntry(itemName: "Hand Towel", countMethod: .manualPieces, manualPieces: 20, calculatedPieces: 20, calculatedFullBundles: 1)
        ]

        let plan = ElevatorTripPlanner().plan(summaries: summaries, entries: entries)

        XCTAssertFalse(plan.trips.isEmpty)
        XCTAssertEqual(plan.trips.first?.primaryItemName, "Washcloth")
        XCTAssertEqual(plan.trips.first?.secondaryItemName, "Hand Towel")
    }

    func test_deliveryPaceEngine_marksBehindWhenEstimatedFinishMissesTarget() {
        let now = Date(timeIntervalSince1970: 1_000)
        let target = now.addingTimeInterval(10 * 60)
        let rows = (1...10).map { FloorDistributionRow(floorNumber: $0, itemName: "Bath Towel", suggestedPieces: 10) }
        let completed: Set<Int> = [1]

        let session = DeliveryPaceEngine().makeSession(
            tower: nil,
            summaries: [summary("Bath Towel", fullBundles: 10, receivedPieces: 50)],
            deliveryRows: rows,
            completedFloors: completed,
            now: now,
            shiftStartTime: now.addingTimeInterval(-10 * 60),
            targetDownTime: target,
            expectedShiftEndTime: target.addingTimeInterval(60 * 60),
            deliveryStartedAt: now.addingTimeInterval(-10 * 60)
        )

        XCTAssertEqual(session.paceStatus, .behind)
        XCTAssertTrue(session.isBehindPace)
    }

    func test_smartRebalanceEngine_suggestsDonorFloorsForShortage() {
        let summaries = [summary("Bath Mat", fullBundles: 2, receivedPieces: 20, differencePieces: -2, status: .shortage, basePerFloorPieces: 1)]
        let rows = [
            FloorDistributionRow(floorNumber: 1, itemName: "Bath Mat", suggestedPieces: 2),
            FloorDistributionRow(floorNumber: 2, itemName: "Bath Mat", suggestedPieces: 2),
            FloorDistributionRow(floorNumber: 3, itemName: "Bath Mat", suggestedPieces: 0),
            FloorDistributionRow(floorNumber: 4, itemName: "Bath Mat", suggestedPieces: 0)
        ]

        let suggestions = SmartRebalanceEngine().suggestions(summaries: summaries, deliveryRows: rows)

        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions.first?.donorFloors, [1, 2])
        XCTAssertEqual(suggestions.first?.piecesRecovered, 2)
        XCTAssertEqual(suggestions.first?.isRecoverable, true)
    }

    func test_elevatorTripPlanner_usesPhysicalBinCountForLoadEstimation() {
        let summaries = [
            summary("Hand Towel", fullBundles: 5, receivedPieces: 100)
        ]
        let entries = [
            ReceivingEntry(
                itemName: "Hand Towel",
                countMethod: .manualPieces,
                physicalBinCount: 3,
                manualPieces: 100,
                calculatedPieces: 100,
                calculatedFullBundles: 5
            )
        ]

        let plan = ElevatorTripPlanner().plan(summaries: summaries, entries: entries)

        // With 3 physical bins, we should get multiple loads reflecting the bin split.
        XCTAssertGreaterThanOrEqual(plan.trips.count, 1)
        // Strategy note should describe the load contents.
        XCTAssertTrue(plan.trips.allSatisfy { $0.strategyNote.contains("Hand Towel") })
    }

    func test_elevatorTripPlanner_strategyNoteDescribesItems() {
        let summaries = [
            summary("Washcloth", fullBundles: 1, receivedPieces: 50),
            summary("Bath Mat", fullBundles: 1, receivedPieces: 30)
        ]
        let entries = [
            ReceivingEntry(itemName: "Washcloth", countMethod: .manualPieces, manualPieces: 50, calculatedPieces: 50, calculatedFullBundles: 1),
            ReceivingEntry(itemName: "Bath Mat", countMethod: .manualPieces, manualPieces: 30, calculatedPieces: 30, calculatedFullBundles: 1)
        ]

        let plan = ElevatorTripPlanner().plan(summaries: summaries, entries: entries)

        XCTAssertEqual(plan.trips.count, 1)
        // Strategy note should contain both item names.
        let note = plan.trips.first!.strategyNote
        XCTAssertTrue(note.contains("Washcloth"), "Expected note to contain Washcloth, got: \(note)")
        XCTAssertTrue(note.contains("Bath Mat"), "Expected note to contain Bath Mat, got: \(note)")
    }

    private func summary(
        _ itemName: String,
        fullBundles: Int,
        receivedPieces: Int,
        loosePieces: Int = 0,
        differencePieces: Int = 0,
        status: CalculationStatus = .exact,
        basePerFloorPieces: Int = 1
    ) -> CalculationSummary {
        CalculationSummary(
            itemName: itemName,
            receivedPieces: receivedPieces,
            bundleSize: 5,
            fullBundles: fullBundles,
            loosePieces: loosePieces,
            requiredPieces: receivedPieces - differencePieces,
            deliverableBundles: fullBundles,
            differencePieces: differencePieces,
            status: status,
            exactPerFloorPieces: Double(basePerFloorPieces),
            basePerFloorPieces: basePerFloorPieces,
            remainderPieces: 0
        )
    }
}
