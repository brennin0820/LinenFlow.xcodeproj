import XCTest
import SwiftData
@testable import HimmerFlow

@MainActor
final class TowerConfigServiceTests: XCTestCase {

    private var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Tower.self,
            migrationPlan: HimmerFlowMigrationPlan.self,
            configurations: config
        )
        SeedService.seedIfNeeded(context: container.mainContext)
    }

    override func tearDownWithError() throws {
        container = nil
    }

    private func tower(named name: String) throws -> Tower {
        let towers = try container.mainContext.fetch(FetchDescriptor<Tower>())
        return try XCTUnwrap(towers.first { $0.name == name })
    }

    func test_effectiveFloorCount_usesPolicyForLagoon() throws {
        let lagoon = try tower(named: "Lagoon")
        XCTAssertEqual(TowerConfigService.effectiveFloorCount(for: lagoon), 21)
    }

    func test_updateFloorCount_clampsToPolicyForProtectedTower() throws {
        let lagoon = try tower(named: "Lagoon")
        lagoon.floorCount = 10
        let result = TowerConfigService.updateFloorCount(50, for: lagoon, context: container.mainContext)
        XCTAssertEqual(result, .clampedToPolicy(protectedCount: 21))
        XCTAssertEqual(lagoon.floorCount, 21)
    }

    func test_updateFloorCount_clampsRequestToValidRange() throws {
        let custom = Tower(name: "Custom Tower", floorCount: 10)
        container.mainContext.insert(custom)
        try container.mainContext.save()

        let result = TowerConfigService.updateFloorCount(999, for: custom, context: container.mainContext)
        XCTAssertEqual(result, .updated(newCount: 80))
        XCTAssertEqual(custom.floorCount, 80)
    }

    func test_updateFloorCount_returnsUnchangedWhenAlreadyAtValue() throws {
        let custom = Tower(name: "Stable Tower", floorCount: 12)
        container.mainContext.insert(custom)
        try container.mainContext.save()

        let result = TowerConfigService.updateFloorCount(12, for: custom, context: container.mainContext)
        XCTAssertEqual(result, .unchanged)
    }

    func test_updateFloorRange_setsFloorCountAndSequence() throws {
        let custom = Tower(name: "Range Tower", floorCount: 5)
        container.mainContext.insert(custom)
        try container.mainContext.save()

        let result = TowerConfigService.updateFloorRange(
            startFloor: 3,
            topFloor: 7,
            skip13thFloor: false,
            for: custom,
            context: container.mainContext
        )
        XCTAssertEqual(result, .updated(floorCount: 5, floors: [3, 4, 5, 6, 7]))
        XCTAssertEqual(custom.floorCount, 5)
        XCTAssertTrue(custom.hasCustomFloorRange)
    }

    func test_updateFloorRange_skips13thWhenRequested() throws {
        let custom = Tower(name: "Skip Tower", floorCount: 5)
        container.mainContext.insert(custom)
        try container.mainContext.save()

        let result = TowerConfigService.updateFloorRange(
            startFloor: 12,
            topFloor: 14,
            skip13thFloor: true,
            for: custom,
            context: container.mainContext
        )
        XCTAssertEqual(result, .updated(floorCount: 2, floors: [12, 14]))
    }

    func test_updateFloorRange_invalidRangeReturnsFailure() throws {
        let custom = Tower(name: "Invalid Tower", floorCount: 5)
        container.mainContext.insert(custom)
        try container.mainContext.save()

        let result = TowerConfigService.updateFloorRange(
            startFloor: 10,
            topFloor: 5,
            skip13thFloor: false,
            for: custom,
            context: container.mainContext
        )
        XCTAssertEqual(result, .invalidRange)
    }
}
