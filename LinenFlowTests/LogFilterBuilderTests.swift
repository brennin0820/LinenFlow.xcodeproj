import XCTest
@testable import HimmerFlow

final class LogFilterBuilderTests: XCTestCase {

    private func makeLog(
        towerName: String,
        statuses: [CalculationStatus],
        date: Date = .now
    ) -> DailyLog {
        let summaries = statuses.enumerated().map { index, status in
            CalculationSummary(
                itemName: "Item \(index)",
                receivedPieces: 10,
                bundleSize: 5,
                fullBundles: 2,
                loosePieces: 0,
                requiredPieces: 12,
                differencePieces: -2,
                status: status,
                exactPerFloorPieces: 1,
                basePerFloorPieces: 1,
                remainderPieces: 0
            )
        }
        return DailyLog(
            date: date,
            towerName: towerName,
            floorCount: 15,
            entriesSnapshot: [],
            summarySnapshot: summaries,
            distributionSnapshot: []
        )
    }

    func test_filterAll_returnsEveryLog() {
        let logs = [
            makeLog(towerName: "Lagoon", statuses: [.exact]),
            makeLog(towerName: "GI", statuses: [.shortage]),
        ]
        XCTAssertEqual(LogFilterBuilder.filter(logs, by: .all).count, 2)
    }

    func test_filterTower_matchesTowerNameExactly() {
        let logs = [
            makeLog(towerName: "Lagoon", statuses: [.exact]),
            makeLog(towerName: "GI", statuses: [.exact]),
            makeLog(towerName: "Lagoon", statuses: [.overage]),
        ]
        let filtered = LogFilterBuilder.filter(logs, by: .tower("Lagoon"))
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.towerName == "Lagoon" })
    }

    func test_filterShortages_onlyLogsWithShortageStatus() {
        let logs = [
            makeLog(towerName: "Lagoon", statuses: [.exact, .shortage]),
            makeLog(towerName: "GI", statuses: [.exact]),
            makeLog(towerName: "GW", statuses: [.shortage]),
        ]
        let filtered = LogFilterBuilder.filter(logs, by: .shortages)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { log in
            log.summarySnapshot.contains { $0.status == .shortage }
        })
    }

    func test_counts_returnsNonZeroForAllAndShortages() {
        let logs = [
            makeLog(towerName: "Lagoon", statuses: [.shortage]),
            makeLog(towerName: "GI", statuses: [.exact]),
        ]
        let counts = LogFilterBuilder.counts(for: logs)
        XCTAssertEqual(counts[.all], 2)
        XCTAssertEqual(counts[.shortages], 1)
        XCTAssertEqual(counts[.tower("Lagoon")], 1)
        XCTAssertEqual(counts[.tower("GI")], 1)
    }
}
