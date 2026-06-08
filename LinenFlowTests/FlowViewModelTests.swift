import XCTest
import SwiftData
@testable import HimmerFlow

@MainActor
final class FlowViewModelTests: XCTestCase {

    var container: ModelContainer!
    var viewModel: FlowViewModel!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Tower.self, LinenItem.self, DailyLog.self,
            configurations: config
        )
        SeedService.seedIfNeeded(context: container.mainContext)
        SharedWidgetStateManager.clear()
        viewModel = FlowViewModel(modelContext: container.mainContext)
    }

    override func tearDownWithError() throws {
        SharedWidgetStateManager.clear()
        viewModel = nil
        container = nil
    }

    // MARK: - Demo Day

    func test_seedData_includesTapaAndRainbow() {
        let towerNames = Set(viewModel.availableTowers.map(\.name))

        XCTAssertTrue(towerNames.contains("Tapa"))
        XCTAssertTrue(towerNames.contains("Rainbow"))
    }

    func test_seedData_includesTwinSheetAndTwinCover() {
        let twinSheet = viewModel.availableItems.first { $0.name == "Twin Sheet" }
        let twinCover = viewModel.availableItems.first { $0.name == "Twin Cover" }

        XCTAssertEqual(twinSheet?.bundleSize, 5)
        XCTAssertEqual(twinSheet?.parCount, 4)
        XCTAssertEqual(twinSheet?.countMethod, .manualPieces)

        XCTAssertEqual(twinCover?.bundleSize, 5)
        XCTAssertEqual(twinCover?.parCount, 4)
        XCTAssertEqual(twinCover?.countMethod, .manualPieces)
    }

    func test_seedData_towerAccentColorsArePopulated() {
        for tower in viewModel.availableTowers {
            XCTAssertFalse(tower.identityColorHex?.isEmpty ?? true, "\(tower.name) should have an accent color")
        }
    }

    func test_seedData_giUsesRealDeliveryFloors() {
        let gi = viewModel.availableTowers.first { $0.name == "GI" }

        XCTAssertEqual(gi?.floorCount, 32)
        XCTAssertEqual(FloorNumberingService.deliveryFloors(towerName: "GI", floorCount: 32).first, 4)
        XCTAssertEqual(FloorNumberingService.deliveryFloors(towerName: "GI", floorCount: 32).last, 36)
        XCTAssertFalse(FloorNumberingService.deliveryFloors(towerName: "GI", floorCount: 32).contains(13))
    }

    func test_seedData_confirmedDeliveryFloorCounts() {
        XCTAssertEqual(viewModel.availableTowers.first { $0.name == "GW" }?.floorCount, 32)
        XCTAssertEqual(viewModel.availableTowers.first { $0.name == "Tapa" }?.floorCount, 33)
        XCTAssertEqual(viewModel.availableTowers.first { $0.name == "Diamond" }?.floorCount, 15)
        XCTAssertEqual(viewModel.availableTowers.first { $0.name == "Alii" }?.floorCount, 14)
    }

    func test_loadDemoDay_selectsLagoon21Floors() {
        viewModel.loadDemoDay()
        XCTAssertEqual(viewModel.selectedTower?.name, "Lagoon")
        XCTAssertEqual(viewModel.selectedTower?.floorCount, 21)
        XCTAssertTrue(viewModel.isDemoDay)
    }

    func test_loadDemoDay_addsFiveEntries() {
        viewModel.loadDemoDay()
        XCTAssertEqual(viewModel.receivingEntries.count, 5)
    }

    func test_loadDemoDay_bathTowelReceivedIs490() {
        viewModel.loadDemoDay()
        let entry = viewModel.receivingEntries.first { $0.itemName == "Bath Towel" }
        XCTAssertEqual(entry?.calculatedPieces, 490)
        XCTAssertEqual(entry?.calculatedFullBundles, 98)
    }

    func test_loadDemoDay_bathTowelDifferenceIsZero() {
        viewModel.loadDemoDay()
        let s = viewModel.calculationSummaries.first { $0.itemName == "Bath Towel" }
        XCTAssertEqual(s?.differencePieces, 0)
        XCTAssertEqual(s?.status, .exact)
    }

    func test_loadDemoDay_bathMatDifferenceIsZero() {
        viewModel.loadDemoDay()
        let s = viewModel.calculationSummaries.first { $0.itemName == "Bath Mat" }
        XCTAssertEqual(s?.differencePieces, 0)
        XCTAssertEqual(s?.status, .exact)
    }

    func test_loadDemoDay_handTowelDifferenceIsZero() {
        viewModel.loadDemoDay()
        let s = viewModel.calculationSummaries.first { $0.itemName == "Hand Towel" }
        XCTAssertEqual(s?.differencePieces, 0)
    }

    func test_loadDemoDay_washclothDifferenceIsZero() {
        viewModel.loadDemoDay()
        let s = viewModel.calculationSummaries.first { $0.itemName == "Washcloth" }
        XCTAssertEqual(s?.differencePieces, 0)
    }

    func test_loadDemoDay_pillowCaseDifferenceIsZero() {
        viewModel.loadDemoDay()
        let s = viewModel.calculationSummaries.first { $0.itemName == "Pillow Case" }
        XCTAssertEqual(s?.differencePieces, 0)
    }

    func test_loadDemoDay_timeshareDoesNotUseParShortages() {
        viewModel.loadDemoDay()

        XCTAssertFalse(viewModel.usesParSystem)
        XCTAssertTrue(viewModel.calculationSummaries.allSatisfy { $0.status == .exact })
        XCTAssertTrue(viewModel.calculationSummaries.allSatisfy { $0.shortageBundles == 0 })
        XCTAssertFalse(viewModel.validationWarnings.contains { $0.localizedCaseInsensitiveContains("short") })
    }

    // MARK: - Diamond example

    func test_loadDiamondDHead_combinedCanonicalTotals() {
        viewModel.loadDiamondDHeadExample()
        XCTAssertEqual(viewModel.selectedTower?.name, "Diamond")
        XCTAssertEqual(viewModel.selectedTower?.floorCount, 15)

        let doubleCover = viewModel.calculationSummaries.first { $0.itemName == "Double Cover" }
        XCTAssertEqual(doubleCover?.receivedPieces, 116, "Double Cover 51 + 65 = 116")
        XCTAssertEqual(doubleCover?.fullBundles, 23)
        XCTAssertEqual(doubleCover?.loosePieces, 1)

        let doubleSheet = viewModel.calculationSummaries.first { $0.itemName == "Double Sheet" }
        XCTAssertEqual(doubleSheet?.receivedPieces, 89, "Double Sheet 39 + 50 = 89")
        XCTAssertEqual(doubleSheet?.fullBundles, 17)
        XCTAssertEqual(doubleSheet?.loosePieces, 4)

        let kingSheet = viewModel.calculationSummaries.first { $0.itemName == "King Sheet" }
        XCTAssertEqual(kingSheet?.receivedPieces, 50)
        XCTAssertEqual(kingSheet?.fullBundles, 10)
        XCTAssertEqual(kingSheet?.loosePieces, 0)

        let kingCover = viewModel.calculationSummaries.first { $0.itemName == "King Cover" }
        XCTAssertEqual(kingCover?.receivedPieces, 50)
        XCTAssertEqual(kingCover?.fullBundles, 10)
        XCTAssertEqual(kingCover?.loosePieces, 0)

        let totalPieces = viewModel.calculationSummaries.reduce(0) { $0 + $1.receivedPieces }
        let totalBundles = viewModel.calculationSummaries.reduce(0) { $0 + $1.fullBundles }
        let totalLoose = viewModel.calculationSummaries.reduce(0) { $0 + $1.loosePieces }
        XCTAssertEqual(totalPieces, 305)
        XCTAssertEqual(totalBundles, 60)
        XCTAssertEqual(totalLoose, 5)
    }

    // MARK: - Build daily log

    func test_buildDailyLog_returnsSnapshotForLagoon() {
        viewModel.loadDemoDay()
        let log = viewModel.buildDailyLog()
        XCTAssertNotNil(log)
        XCTAssertEqual(log?.towerName, "Lagoon")
        XCTAssertEqual(log?.floorCount, 21)
        XCTAssertEqual(log?.entriesSnapshot.count, 5)
        XCTAssertEqual(log?.summarySnapshot.count, 5)
    }

    func test_lagoonDeliveryPlanUsesPieces() {
        viewModel.loadDemoDay()

        XCTAssertFalse(viewModel.deliveryUnitIsBundles)
        let bathTowelFloor3 = viewModel.deliveryFloorDistributions.first {
            $0.itemName == "Bath Towel" && $0.floorNumber == 3
        }

        XCTAssertEqual(bathTowelFloor3?.suggestedPieces, 24)
        XCTAssertNil(bathTowelFloor3?.suggestedBundles)
    }

    func test_diamondDeliveryPlanUsesBundles() {
        viewModel.loadDiamondDHeadExample()

        XCTAssertTrue(viewModel.deliveryUnitIsBundles)
        let doubleCoverFloor1 = viewModel.deliveryFloorDistributions.first {
            $0.itemName == "Double Cover" && $0.floorNumber == 1
        }

        XCTAssertEqual(doubleCoverFloor1?.suggestedPieces, 0)
        XCTAssertEqual(doubleCoverFloor1?.suggestedBundles, 2)
    }

    func test_towerParRequirements_matchesCalculationSummary() {
        viewModel.loadDiamondDHeadExample()

        let summaryNames = Set(viewModel.calculationSummaries.map(\.itemName))
        for requirement in viewModel.towerParRequirements where summaryNames.contains(requirement.itemName) {
            let summary = viewModel.calculationSummaries.first { $0.itemName == requirement.itemName }
            XCTAssertNotNil(summary, "Missing summary for \(requirement.itemName)")
            XCTAssertEqual(requirement.requiredBundles, summary?.requiredBundles, requirement.itemName)
            XCTAssertEqual(requirement.requiredPieces, summary?.requiredPieces, requirement.itemName)
            XCTAssertEqual(requirement.pieceGap, summary?.differencePieces, requirement.itemName)
            XCTAssertEqual(requirement.bundleGap, summary?.differenceBundles, requirement.itemName)
            XCTAssertEqual(requirement.receivedBundles, summary?.fullBundles, requirement.itemName)
        }
    }

    func test_giDeliveryPlanUsesPieces() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let gi = try XCTUnwrap(towers.first { $0.name == "GI" })
        viewModel.selectTower(gi)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let bathTowel = try XCTUnwrap(items.first { $0.name == "Bath Towel" })
        viewModel.addOrUpdateReceivedPieces(item: bathTowel, pieces: 245)

        XCTAssertFalse(viewModel.deliveryUnitIsBundles)
        let row = viewModel.deliveryFloorDistributions.first {
            $0.itemName == "Bath Towel" && $0.floorNumber == 4
        }
        XCTAssertEqual(row?.suggestedPieces, 8)
        XCTAssertNil(row?.suggestedBundles)
    }

    func test_giDeliveryPlanLabelsFloorsFromFourToThirtySixSkippingThirteen() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let gi = try XCTUnwrap(towers.first { $0.name == "GI" })
        viewModel.selectTower(gi)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let bathTowel = try XCTUnwrap(items.first { $0.name == "Bath Towel" })
        viewModel.addOrUpdateReceivedPieces(item: bathTowel, pieces: 245)

        let bathTowelRows = viewModel.deliveryFloorDistributions.filter { $0.itemName == "Bath Towel" }
        XCTAssertEqual(bathTowelRows.count, 32)
        XCTAssertEqual(bathTowelRows.first?.floorNumber, 4)
        XCTAssertEqual(bathTowelRows.last?.floorNumber, 36)
        XCTAssertFalse(bathTowelRows.contains { $0.floorNumber == 13 })
    }

    func test_gwDeliveryPlanUsesExplicitThirtyTwoFloorsAndSkipsClosedFloors() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let gw = try XCTUnwrap(towers.first { $0.name == "GW" })
        viewModel.selectTower(gw)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let bathTowel = try XCTUnwrap(items.first { $0.name == "Bath Towel" })
        viewModel.addOrUpdateReceivedPieces(item: bathTowel, pieces: 245)

        let bathTowelRows = viewModel.deliveryFloorDistributions.filter { $0.itemName == "Bath Towel" }
        XCTAssertEqual(bathTowelRows.count, 32)
        XCTAssertEqual(bathTowelRows.first?.floorNumber, 5)
        XCTAssertEqual(bathTowelRows.last?.floorNumber, 39)
        XCTAssertFalse(bathTowelRows.contains { [13, 33, 34].contains($0.floorNumber) })
    }

    func test_tapaDeliveryPlanLabelsFloorsThreeThroughThirtyFive() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let tapa = try XCTUnwrap(towers.first { $0.name == "Tapa" })
        viewModel.selectTower(tapa)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let kingSheet = try XCTUnwrap(items.first { $0.name == "King Sheet" })
        viewModel.addOrUpdateReceivedPieces(item: kingSheet, pieces: 165)

        let rows = viewModel.deliveryFloorDistributions.filter { $0.itemName == "King Sheet" }
        XCTAssertEqual(rows.count, 33)
        XCTAssertEqual(rows.first?.floorNumber, 3)
        XCTAssertEqual(rows.last?.floorNumber, 35)
    }

    func test_updateSelectedTowerFloorCount_recalculatesDeliveryPlan() {
        viewModel.resetFlow()
        let tower = Tower(name: "Generic", floorCount: 25, deliveryMode: .pieces)
        viewModel.selectTower(tower)
        let bathTowel = viewModel.availableItems.first { $0.name == "Bath Towel" }!
        viewModel.addOrUpdateReceivedPieces(item: bathTowel, pieces: 245)

        viewModel.updateSelectedTowerFloorCount(20)

        XCTAssertEqual(viewModel.selectedTower?.floorCount, 20)
        let bathTowelRows = viewModel.deliveryFloorDistributions.filter { $0.itemName == "Bath Towel" }
        XCTAssertEqual(bathTowelRows.count, 20)
    }

    func test_resetTowerFloorRangeToDefaults_restoresGWLegacyFallback() {
        let gw = viewModel.availableTowers.first { $0.name == "GW" }!

        // Push GW into a simple custom range first.
        viewModel.updateTowerFloorRange(gw, startFloor: 1, topFloor: 20, skip13thFloor: false)
        XCTAssertTrue(gw.hasCustomFloorRange)
        XCTAssertEqual(gw.floorCount, 20)

        // Reset back to the seeded defaults. GW is seeded with unset range so
        // the legacy multi-gap sequence in DeliveryFloorSequenceService applies.
        viewModel.resetTowerFloorRangeToDefaults(gw)

        XCTAssertEqual(gw.startFloor, 0)
        XCTAssertEqual(gw.topFloor, 0)
        XCTAssertFalse(gw.skip13thFloor)
        XCTAssertFalse(gw.hasCustomFloorRange)
        XCTAssertEqual(gw.floorCount, 32)

        let floors = DeliveryFloorSequenceService.deliveryFloors(for: gw)
        XCTAssertEqual(floors, Array(5...12) + Array(14...32) + Array(35...39))
        XCTAssertFalse(floors.contains(13))
    }

    func test_buildDailyLog_returnsNilWithoutTowerOrEntries() {
        viewModel.resetFlow()
        XCTAssertNil(viewModel.buildDailyLog())
    }

    func test_selectingCurrentDeliveryItemDoesNotActivateWidgetSession() {
        viewModel.loadDemoDay()

        viewModel.setCurrentDeliveryItem("Bath Towel")

        let widgetState = SharedWidgetStateManager.load()
        XCTAssertEqual(widgetState.currentItemName, "Bath Towel")
        XCTAssertFalse(widgetState.isActiveSession)
        XCTAssertFalse(viewModel.deliverySessionState.isActive)
    }

    func test_startDeliverySessionActivatesWidgetSession() {
        viewModel.loadDemoDay()
        viewModel.setCurrentDeliveryItem("Bath Towel")

        viewModel.startDeliverySession()

        let widgetState = SharedWidgetStateManager.load()
        XCTAssertTrue(widgetState.isActiveSession)
        XCTAssertTrue(viewModel.deliverySessionState.isActive)
        XCTAssertEqual(widgetState.currentItemName, "Bath Towel")
    }

    func test_pauseDeliverySessionMarksWidgetPaused() {
        viewModel.loadDemoDay()
        viewModel.setCurrentDeliveryItem("Bath Towel")
        viewModel.startDeliverySession()

        viewModel.pauseDeliverySession()

        let widgetState = SharedWidgetStateManager.load()
        XCTAssertTrue(widgetState.isActiveSession)
        XCTAssertEqual(widgetState.isPausedSession, true)
        XCTAssertTrue(widgetState.statusText.localizedCaseInsensitiveContains("paused"))
    }

    func test_markFloorCompleteAddsDeliveryFloor() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let firstFloor = try XCTUnwrap(viewModel.deliverySessionState.deliveryFloors.first)

        viewModel.markFloorComplete(firstFloor)

        XCTAssertTrue(viewModel.deliverySessionState.completedFloorNumbers.contains(firstFloor))
        XCTAssertEqual(viewModel.deliverySessionState.completedCount, 1)
        XCTAssertEqual(SharedWidgetStateManager.load().completedFloors, 1)
    }

    func test_unmarkFloorCompleteRemovesDeliveryFloor() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let firstFloor = try XCTUnwrap(viewModel.deliverySessionState.deliveryFloors.first)
        viewModel.markFloorComplete(firstFloor)

        viewModel.unmarkFloorComplete(firstFloor)

        XCTAssertFalse(viewModel.deliverySessionState.completedFloorNumbers.contains(firstFloor))
        XCTAssertEqual(viewModel.deliverySessionState.completedCount, 0)
        XCTAssertEqual(SharedWidgetStateManager.load().completedFloors, 0)
    }

    func test_toggleFloorCompleteTogglesDeliveryFloor() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let firstFloor = try XCTUnwrap(viewModel.deliverySessionState.deliveryFloors.first)

        viewModel.toggleFloorComplete(firstFloor)
        XCTAssertTrue(viewModel.deliverySessionState.completedFloorNumbers.contains(firstFloor))

        viewModel.toggleFloorComplete(firstFloor)
        XCTAssertFalse(viewModel.deliverySessionState.completedFloorNumbers.contains(firstFloor))
    }

    func test_loadFromLog_restoresEntriesNotesAndRecalculates() throws {
        viewModel.loadDemoDay()
        viewModel.notes = "Repeat this setup"
        let log = try XCTUnwrap(viewModel.buildDailyLog())

        viewModel.clearEntries()
        XCTAssertTrue(viewModel.receivingEntries.isEmpty)

        viewModel.loadFromLog(log)

        XCTAssertEqual(viewModel.selectedTower?.name, "Lagoon")
        XCTAssertEqual(viewModel.notes, "Repeat this setup")
        XCTAssertEqual(viewModel.receivingEntries.count, 5)
        XCTAssertEqual(viewModel.calculationSummaries.count, 5)
        XCTAssertEqual(
            viewModel.calculationSummaries.first { $0.itemName == "Bath Towel" }?.receivedPieces,
            490
        )
    }

    func test_dailyLogSnapshotDoesNotMutateWhenCurrentSettingsChange() throws {
        viewModel.loadDemoDay()
        let log = try XCTUnwrap(viewModel.buildDailyLog())

        let bathTowel = try XCTUnwrap(viewModel.availableItems.first { $0.name == "Bath Towel" })
        bathTowel.parCount = 99
        viewModel.recalculate()

        XCTAssertEqual(log.summarySnapshot.first { $0.itemName == "Bath Towel" }?.receivedPieces, 490)
        XCTAssertEqual(log.floorCount, 21)
    }

    // MARK: - Safety / validation

    func test_recalculate_withoutTower_isSafe() {
        viewModel.resetFlow()
        viewModel.recalculate()
        XCTAssertTrue(viewModel.calculationSummaries.isEmpty)
        XCTAssertTrue(viewModel.floorDistributions.isEmpty)
    }

    func test_validation_emptyStateWarns() {
        viewModel.resetFlow()
        viewModel.validateInputs()
        XCTAssertTrue(viewModel.validationWarnings.contains { $0.contains("Select a tower") })
        XCTAssertTrue(viewModel.validationWarnings.contains { $0.contains("at least one received item") })
    }

    func test_validation_doubleSheetInLagoonProducesWarning() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let lagoon = try XCTUnwrap(towers.first { $0.name == "Lagoon" })
        viewModel.selectTower(lagoon)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let doubleSheet = try XCTUnwrap(items.first { $0.name == "Double Sheet" })
        viewModel.addOrUpdateReceivingEntry(item: doubleSheet, manualPieces: 20)

        XCTAssertTrue(viewModel.validationWarnings.contains { $0.contains("Diamond and Alii") },
                      "expected the Double Sheet warning; got \(viewModel.validationWarnings)")
    }

    func test_validation_warnsWhenReceivedPiecesDoNotMakeFullBundle() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let diamond = try XCTUnwrap(towers.first { $0.name == "Diamond" })
        viewModel.selectTower(diamond)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let bathMat = try XCTUnwrap(items.first { $0.name == "Bath Mat" })
        viewModel.addOrUpdateReceivingEntry(item: bathMat, manualPieces: 9)

        XCTAssertTrue(
            viewModel.validationWarnings.contains { $0.contains("Bath Mat") && $0.contains("do not make a full bundle") },
            "expected the zero full-bundle warning; got \(viewModel.validationWarnings)"
        )
    }

    func test_validation_warnsWhenLoosePiecesAreCloseToAnotherBundle() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let diamond = try XCTUnwrap(towers.first { $0.name == "Diamond" })
        viewModel.selectTower(diamond)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let doubleSheet = try XCTUnwrap(items.first { $0.name == "Double Sheet" })
        viewModel.addOrUpdateReceivingEntry(item: doubleSheet, manualPieces: 9)

        XCTAssertTrue(
            viewModel.validationWarnings.contains { $0.contains("Double Sheet") && $0.contains("close to another bundle") },
            "expected the large loose-piece warning; got \(viewModel.validationWarnings)"
        )
    }

    func test_validation_warnsAboutBundleShortage() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let diamond = try XCTUnwrap(towers.first { $0.name == "Diamond" })
        viewModel.selectTower(diamond)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let kingSheet = try XCTUnwrap(items.first { $0.name == "King Sheet" })
        viewModel.addOrUpdateReceivingEntry(item: kingSheet, manualPieces: 5)

        XCTAssertTrue(
            viewModel.validationWarnings.contains { $0.contains("King Sheet") && $0.contains("short") && $0.contains("bundles") },
            "expected the bundle shortage warning; got \(viewModel.validationWarnings)"
        )
    }

    func test_saveSelectedItems_updatesTowerItemAvailabilityAndRemovesDeselectedEntries() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let lagoon = try XCTUnwrap(towers.first { $0.name == "Lagoon" })
        viewModel.selectTower(lagoon)

        let bathTowel = try XCTUnwrap(viewModel.availableItems.first { $0.name == "Bath Towel" })
        let bathMat = try XCTUnwrap(viewModel.availableItems.first { $0.name == "Bath Mat" })
        viewModel.addOrUpdateReceivedPieces(item: bathTowel, pieces: 245)
        viewModel.addOrUpdateReceivedPieces(item: bathMat, pieces: 60)

        try viewModel.saveSelectedItems([bathTowel.id], for: lagoon)

        XCTAssertTrue(viewModel.itemIsAvailable(bathTowel, for: lagoon))
        XCTAssertFalse(viewModel.itemIsAvailable(bathMat, for: lagoon))
        XCTAssertEqual(viewModel.receivingEntries.map(\.itemName), ["Bath Towel"])
    }

    // MARK: - Industrial hardening: session re-entry / tower switch / widget integrity

    func test_startDeliverySession_isNoOpWhenAlreadyActive() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let firstFloor = try XCTUnwrap(viewModel.deliverySessionState.deliveryFloors.first)
        viewModel.markFloorComplete(firstFloor)
        XCTAssertEqual(viewModel.deliverySessionState.completedCount, 1)

        viewModel.startDeliverySession()  // second call — must not reset progress

        XCTAssertTrue(viewModel.deliverySessionState.isActive)
        XCTAssertEqual(viewModel.deliverySessionState.completedCount, 1,
                       "startDeliverySession while active must not reset completed floors")
    }

    func test_selectTower_clearsActiveDeliverySession() {
        viewModel.loadDemoDay()  // selects Lagoon
        viewModel.startDeliverySession()
        XCTAssertTrue(viewModel.deliverySessionState.isActive)

        let diamond = viewModel.availableTowers.first { $0.name == "Diamond" }!
        viewModel.selectTower(diamond)

        XCTAssertFalse(viewModel.deliverySessionState.isActive,
                       "Switching tower while active must deactivate the delivery session")
        XCTAssertNil(viewModel.currentDeliveryItemName)
        XCTAssertEqual(viewModel.selectedTower?.name, "Diamond")
    }

    func test_selectTower_sameTower_doesNotClearSession() throws {
        viewModel.loadDemoDay()  // selects Lagoon
        viewModel.startDeliverySession()
        let firstFloor = try XCTUnwrap(viewModel.deliverySessionState.deliveryFloors.first)
        viewModel.markFloorComplete(firstFloor)

        let lagoon = viewModel.availableTowers.first { $0.name == "Lagoon" }!
        viewModel.selectTower(lagoon)  // re-selecting the same tower

        XCTAssertTrue(viewModel.deliverySessionState.isActive,
                      "Re-selecting the same tower must not clear an active session")
        XCTAssertEqual(viewModel.deliverySessionState.completedCount, 1)
    }

    func test_recalculate_duringActiveSession_preservesWidgetCompletedFloors() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let firstFloor = try XCTUnwrap(viewModel.deliverySessionState.deliveryFloors.first)
        viewModel.markFloorComplete(firstFloor)
        XCTAssertEqual(viewModel.deliverySessionState.completedCount, 1)

        // Simulate a UI-triggered recalculate (e.g., notes change, item toggle)
        viewModel.recalculate()

        let widgetState = SharedWidgetStateManager.load()
        XCTAssertEqual(widgetState.completedFloors, 1,
                       "recalculate must not reset widget completed floors to 0 while session is active")
        XCTAssertTrue(widgetState.isActiveSession)
    }

    func test_finishDeliverySession_deactivatesSessionAndWidget() {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        XCTAssertTrue(viewModel.deliverySessionState.isActive)

        viewModel.finishDeliverySession()

        XCTAssertFalse(viewModel.deliverySessionState.isActive)
        XCTAssertFalse(SharedWidgetStateManager.load().isActiveSession)
    }

    func test_resumeDeliverySession_clearsPausedState() {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        viewModel.pauseDeliverySession()
        XCTAssertTrue(viewModel.deliverySessionState.isPaused)
        XCTAssertEqual(SharedWidgetStateManager.load().isPausedSession, true)

        viewModel.resumeDeliverySession()

        XCTAssertFalse(viewModel.deliverySessionState.isPaused,
                       "resumeDeliverySession must clear the isPaused flag")
        XCTAssertEqual(SharedWidgetStateManager.load().isPausedSession, false)
        XCTAssertTrue(viewModel.deliverySessionState.isActive)
    }

    func test_markFloorComplete_invalidFloor_isNoOp() {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()

        viewModel.markFloorComplete(9999)  // floor not in delivery floors

        XCTAssertFalse(viewModel.deliverySessionState.completedFloorNumbers.contains(9999))
        XCTAssertEqual(viewModel.deliverySessionState.completedCount, 0)
    }

    func test_clearEntries_resetsDeliverySessionAndDeliveryItem() {
        viewModel.loadDemoDay()
        viewModel.setCurrentDeliveryItem("Bath Towel")
        viewModel.startDeliverySession()
        XCTAssertTrue(viewModel.deliverySessionState.isActive)

        viewModel.clearEntries()

        XCTAssertFalse(viewModel.deliverySessionState.isActive,
                       "clearEntries must deactivate any running delivery session")
        XCTAssertNil(viewModel.currentDeliveryItemName)
        XCTAssertFalse(SharedWidgetStateManager.load().isActiveSession)
    }

    func test_syncWidgetState_nextCarryPreservedAcrossRecalculate() {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        viewModel.setNextCarryGroup("Trip 2: Towels + Mats")
        XCTAssertEqual(viewModel.deliverySessionState.nextCarryGroupTitle, "Trip 2: Towels + Mats")

        viewModel.recalculate()

        let widgetState = SharedWidgetStateManager.load()
        XCTAssertEqual(widgetState.nextCarryGroupTitle, "Trip 2: Towels + Mats",
                       "recalculate must not drop the active session's next carry group title")
    }

    func test_completedFloors_cannotExceedDeliveryFloorCount() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let floors = viewModel.deliverySessionState.deliveryFloors

        for floor in floors { viewModel.markFloorComplete(floor) }
        viewModel.markFloorComplete(9999)  // invalid extra

        XCTAssertEqual(viewModel.deliverySessionState.completedCount, floors.count)
        XCTAssertTrue(viewModel.deliverySessionState.isComplete)
        XCTAssertEqual(viewModel.deliverySessionState.completedFloorNumbers.count, floors.count)
    }

    // MARK: - Floor-aware advancement

    func test_markFloorCompleteAndAdvance_advancesToNextFloor() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let floors = viewModel.deliverySessionState.deliveryFloors
        let firstFloor = try XCTUnwrap(floors.first)

        viewModel.markFloorCompleteAndAdvance(firstFloor)

        XCTAssertTrue(viewModel.deliverySessionState.completedFloorNumbers.contains(firstFloor))
        XCTAssertEqual(viewModel.deliverySessionState.completedCount, 1)
        // Next carry group should be set
        XCTAssertNotNil(viewModel.deliverySessionState.nextCarryGroupTitle)
    }

    func test_markFloorCompleteAndAdvance_preservesCarryGroupIfStillNeeded() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let floors = viewModel.deliverySessionState.deliveryFloors
        let groups = viewModel.carryGroups
        guard let firstGroup = groups.first else {
            XCTFail("Expected at least one carry group for demo day")
            return
        }

        // Set carry group to first group before advancing
        viewModel.setNextCarryGroup(firstGroup.label)
        viewModel.setCurrentDeliveryItem(firstGroup.itemName)

        let firstFloor = try XCTUnwrap(floors.first)
        let neededOnSecondFloor = viewModel.itemsNeededOnFloor(floors[1])

        // If the first group's item is needed on the second floor, it should be preserved
        viewModel.markFloorCompleteAndAdvance(firstFloor)

        if neededOnSecondFloor.contains(firstGroup.itemName) {
            XCTAssertEqual(viewModel.deliverySessionState.nextCarryGroupTitle, firstGroup.label,
                           "Carry group should be preserved when its item is needed on the next floor")
        } else {
            XCTAssertNotEqual(viewModel.deliverySessionState.nextCarryGroupTitle, firstGroup.label,
                              "Carry group should switch when its item is not needed on the next floor")
        }
    }

    func test_markFloorCompleteAndAdvance_selectsNeededCarryGroupForNextFloor() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let floors = viewModel.deliverySessionState.deliveryFloors
        let firstFloor = try XCTUnwrap(floors.first)

        viewModel.markFloorCompleteAndAdvance(firstFloor)

        guard let nextFloor = viewModel.nextUndoneFloor() else {
            XCTFail("Expected a next undone floor after completing only the first")
            return
        }
        let neededItems = viewModel.itemsNeededOnFloor(nextFloor)

        // The selected carry group's item should be needed on the next floor, or be a fallback
        if let carryTitle = viewModel.deliverySessionState.nextCarryGroupTitle,
           let carryGroup = viewModel.carryGroups.first(where: { $0.label == carryTitle }) {
            if !neededItems.isEmpty {
                XCTAssertTrue(neededItems.contains(carryGroup.itemName),
                              "Selected carry group item '\(carryGroup.itemName)' should be needed on floor \(nextFloor)")
            }
        }
    }

    func test_markFloorCompleteAndAdvance_safeWhenRouteIsComplete() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let floors = viewModel.deliverySessionState.deliveryFloors

        // Complete all floors
        for floor in floors {
            viewModel.markFloorComplete(floor)
        }
        XCTAssertTrue(viewModel.deliverySessionState.isComplete)

        // Calling advance on an already-complete route should be safe (no crash)
        let lastFloor = try XCTUnwrap(floors.last)
        viewModel.markFloorCompleteAndAdvance(lastFloor)

        XCTAssertTrue(viewModel.deliverySessionState.isComplete)
    }

    func test_markFloorCompleteAndAdvance_safeWithNoCarryGroups() throws {
        // Select a tower and start session but with no receiving entries (no carry groups)
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let lagoon = try XCTUnwrap(towers.first { $0.name == "Lagoon" })
        viewModel.selectTower(lagoon)
        viewModel.startDeliverySession()
        let floors = viewModel.deliverySessionState.deliveryFloors

        XCTAssertTrue(viewModel.carryGroups.isEmpty, "No entries means no carry groups")

        let firstFloor = try XCTUnwrap(floors.first)
        viewModel.markFloorCompleteAndAdvance(firstFloor)

        // Should complete floor without crash, no carry group to set
        XCTAssertTrue(viewModel.deliverySessionState.completedFloorNumbers.contains(firstFloor))
    }

    func test_nextUndoneFloor_returnsFirstIncomplete() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let floors = viewModel.deliverySessionState.deliveryFloors

        XCTAssertEqual(viewModel.nextUndoneFloor(), floors.first)

        viewModel.markFloorComplete(floors[0])
        XCTAssertEqual(viewModel.nextUndoneFloor(), floors[1])

        viewModel.markFloorComplete(floors[1])
        XCTAssertEqual(viewModel.nextUndoneFloor(), floors[2])
    }

    func test_nextUndoneFloor_nilWhenAllComplete() {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let floors = viewModel.deliverySessionState.deliveryFloors

        for floor in floors { viewModel.markFloorComplete(floor) }
        XCTAssertNil(viewModel.nextUndoneFloor())
    }

    func test_itemsNeededOnFloor_returnsCorrectItems() throws {
        viewModel.loadDemoDay()
        viewModel.startDeliverySession()
        let floors = viewModel.deliverySessionState.deliveryFloors
        let firstFloor = try XCTUnwrap(floors.first)

        let needed = viewModel.itemsNeededOnFloor(firstFloor)

        // Demo day has 5 items for Lagoon — all should have distribution on floor 1
        XCTAssertFalse(needed.isEmpty, "First floor should have items needing delivery")
    }
}
