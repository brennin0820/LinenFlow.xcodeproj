import XCTest
import SwiftData
import os
@testable import HimmerFlow

@MainActor
final class DailyLogSaveTests: XCTestCase {

    var container: ModelContainer!
    var viewModel: FlowViewModel!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Tower.self, LinenItem.self, DailyLog.self,
            migrationPlan: HimmerFlowMigrationPlan.self,
            configurations: config
        )
        SeedService.seedIfNeeded(context: container.mainContext)
        viewModel = FlowViewModel(modelContext: container.mainContext)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        container = nil
    }

    func test_save_failsWithoutTower() {
        viewModel.resetFlow()
        switch DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext) {
        case .success: XCTFail("expected failure when no tower selected")
        case .failure(let err): XCTAssertEqual(err, .noTower)
        }
    }

    func test_save_failsWithoutEntries() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let lagoon = try XCTUnwrap(towers.first { $0.name == "Lagoon" })
        viewModel.selectTower(lagoon)

        switch DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext) {
        case .success: XCTFail("expected failure when no entries")
        case .failure(let err): XCTAssertEqual(err, .noEntries)
        }
    }

    func test_save_succeedsForDemoDay() throws {
        viewModel.loadDemoDay()
        let result = DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext)
        switch result {
        case .success(let log):
            XCTAssertEqual(log.towerName, "Lagoon")
            XCTAssertEqual(log.entriesSnapshot.count, 5)
            XCTAssertEqual(log.summarySnapshot.count, 5)
        case .failure(let err):
            XCTFail("expected success, got \(err)")
        }
    }

    func test_savedLog_persistsAndIsFetchable() throws {
        viewModel.loadDemoDay()
        _ = DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext)

        let fetched = try container.mainContext.fetch(FetchDescriptor<DailyLog>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.towerName, "Lagoon")
        XCTAssertEqual(fetched.first?.entriesSnapshot.count, 5)
    }

    func test_save_sameDaySameTower_updatesInPlace() throws {
        viewModel.loadDemoDay()
        let first = try DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext).get()
        let firstID = first.id

        // Save again for the same tower on the same day.
        let second = try DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext).get()

        // Should reuse the same log, not create a duplicate.
        XCTAssertEqual(second.id, firstID, "Same-day save should update the existing log")
        let fetched = try container.mainContext.fetch(FetchDescriptor<DailyLog>())
        XCTAssertEqual(fetched.count, 1, "Only one log should exist after two same-day saves")
    }

    func test_save_differentTowers_createsSeparateLogs() throws {
        viewModel.loadDemoDay()  // Loads Lagoon
        _ = try DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext).get()

        // Switch to Diamond
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let diamond = try XCTUnwrap(towers.first { $0.name == "Diamond" })
        viewModel.selectTower(diamond)
        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let bathMat = try XCTUnwrap(items.first { $0.name == "Bath Mat" })
        viewModel.addOrUpdateReceivingEntry(item: bathMat, binCount: nil, manualPieces: 45)
        _ = try DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext).get()

        let fetched = try container.mainContext.fetch(FetchDescriptor<DailyLog>())
        XCTAssertEqual(fetched.count, 2, "Different towers should create separate logs")
    }

    func test_savedLog_snapshotIsImmuneToLaterSettingsChanges() throws {
        // Use Diamond — a par-based tower — so that parCount affects requiredPieces.
        // Lagoon is timeshare and ignores par, making this test meaningless there.
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let diamond = try XCTUnwrap(towers.first { $0.name == "Diamond" })
        viewModel.selectTower(diamond)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let bathMat = try XCTUnwrap(items.first { $0.name == "Bath Mat" })
        // Diamond has 15 delivery floors, Bath Mat par = 3 bundles/floor → requiredPieces = 450.
        viewModel.addOrUpdateReceivingEntry(item: bathMat, binCount: nil, manualPieces: 45)
        _ = DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext)

        // Mutate the par count to simulate a later settings change.
        bathMat.parCount = 999
        try container.mainContext.save()

        let fetched = try container.mainContext.fetch(FetchDescriptor<DailyLog>())
        let bathMatSummary = fetched.first?.summarySnapshot.first { $0.itemName == "Bath Mat" }
        // Snapshot must still reflect the original par 3 × 15 floors × 10 pcs/bdl = 450, not the changed 999.
        XCTAssertEqual(bathMatSummary?.requiredPieces, 450)
    }

    func test_savedLog_bundleSizeSnapshotIsImmune() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let diamond = try XCTUnwrap(towers.first { $0.name == "Diamond" })
        viewModel.selectTower(diamond)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let bathMat = try XCTUnwrap(items.first { $0.name == "Bath Mat" })
        let originalBundleSize = bathMat.bundleSize  // 10

        viewModel.addOrUpdateReceivingEntry(item: bathMat, binCount: nil, manualPieces: 45)
        _ = DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext)

        // Mutate the bundle size to simulate a later settings change.
        bathMat.bundleSize = 999
        try container.mainContext.save()

        let fetched = try container.mainContext.fetch(FetchDescriptor<DailyLog>())
        let bathMatSummary = fetched.first?.summarySnapshot.first { $0.itemName == "Bath Mat" }
        // The snapshotted bundle size must still be the original, not 999.
        XCTAssertEqual(bathMatSummary?.bundleSize, originalBundleSize)
    }

    func test_dailyLog_updateReplacesSnapshotData() {
        let log = DailyLog(
            date: .now,
            towerName: "Diamond",
            floorCount: 15,
            entriesSnapshot: [
                ReceivingEntry(itemName: "Bath Mat", countMethod: .manualPieces, manualPieces: 10, calculatedPieces: 10, calculatedFullBundles: 1)
            ],
            summarySnapshot: [],
            distributionSnapshot: []
        )
        XCTAssertEqual(log.entriesSnapshot.count, 1)

        log.update(
            floorCount: 14,
            entriesSnapshot: [
                ReceivingEntry(itemName: "Bath Mat", countMethod: .manualPieces, manualPieces: 20, calculatedPieces: 20, calculatedFullBundles: 2),
                ReceivingEntry(itemName: "Hand Towel", countMethod: .manualPieces, manualPieces: 40, calculatedPieces: 40, calculatedFullBundles: 2)
            ],
            summarySnapshot: [],
            distributionSnapshot: [],
            notes: "Updated"
        )

        XCTAssertEqual(log.floorCount, 14)
        XCTAssertEqual(log.entriesSnapshot.count, 2)
        XCTAssertEqual(log.notes, "Updated")
    }

    func test_migrationPlan_initializesContainerSuccessfully() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let testContainer = try ModelContainer(
            for: Tower.self, LinenItem.self, DailyLog.self,
            migrationPlan: HimmerFlowMigrationPlan.self,
            configurations: config
        )
        XCTAssertNotNil(testContainer)
    }

    func test_recalculateBeforeSave_preservesCorrectValues() throws {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        let lagoon = try XCTUnwrap(towers.first { $0.name == "Lagoon" })
        viewModel.selectTower(lagoon)

        let items = try container.mainContext.fetch(FetchDescriptor<LinenItem>())
        let bathTowel = try XCTUnwrap(items.first { $0.name == "Bath Towel" })

        viewModel.addOrUpdateReceivingEntry(item: bathTowel, binCount: 1, manualPieces: nil)

        // Save
        _ = try DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext).get()

        viewModel.addOrUpdateReceivingEntry(item: bathTowel, binCount: 2, manualPieces: nil)

        let second = try DailyLogSaveService.save(viewModel: viewModel, context: container.mainContext).get()
        let bathTowelSummary = second.summarySnapshot.first { $0.itemName == "Bath Towel" }

        XCTAssertEqual(bathTowelSummary?.receivedPieces, 490)
    }
}
