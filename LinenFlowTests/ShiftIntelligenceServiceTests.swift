import XCTest
@testable import HimmerFlow

final class ShiftIntelligenceServiceTests: XCTestCase {
    private var calendar: Calendar!
    private var service: ShiftIntelligenceService!

    /// Monday, 9 June 2025 (UTC).
    private let referenceMonday = Date(timeIntervalSince1970: 1_749_456_000)
    /// Wednesday, 11 June 2025 (UTC).
    private let referenceWednesday = Date(timeIntervalSince1970: 1_749_628_800)

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
        service = ShiftIntelligenceService(calendar: cal)
    }

    // MARK: - Predictions

    func test_predictions_usesMedianAcrossHistoricalLogs() throws {
        let item = makeItem(name: "King Sheet", countMethod: .manualPieces)
        let tuesdayA = daysBefore(referenceWednesday, 1)
        let tuesdayB = daysBefore(referenceWednesday, 8)
        let tuesdayC = daysBefore(referenceWednesday, 15)
        let logs = [
            makeLog(tower: "Diamond", createdAt: tuesdayA, itemName: item.name, pieces: 100),
            makeLog(tower: "Diamond", createdAt: tuesdayB, itemName: item.name, pieces: 120),
            makeLog(tower: "Diamond", createdAt: tuesdayC, itemName: item.name, pieces: 110),
        ]

        let predictions = service.predictions(
            towerName: "Diamond",
            items: [item],
            logs: logs,
            referenceDate: referenceWednesday
        )

        XCTAssertEqual(predictions.count, 1)
        let prediction = try XCTUnwrap(predictions.first)
        XCTAssertEqual(prediction.predictedPieces, 110)
        XCTAssertEqual(prediction.sampleCount, 3)
        XCTAssertEqual(prediction.sameWeekdaySampleCount, 0)
        XCTAssertTrue(prediction.typicalLabel.contains("Diamond"))
    }

    func test_predictions_prefersSameWeekdaySamplesWhenAvailable() throws {
        let item = makeItem(name: "King Sheet", countMethod: .manualPieces)
        let mondayA = referenceMonday
        let mondayB = daysBefore(referenceMonday, 7)
        let tuesday = daysAfter(referenceMonday, 1)

        let logs = [
            makeLog(tower: "Diamond", createdAt: mondayA, itemName: item.name, pieces: 80),
            makeLog(tower: "Diamond", createdAt: mondayB, itemName: item.name, pieces: 100),
            makeLog(tower: "Diamond", createdAt: tuesday, itemName: item.name, pieces: 200),
            makeLog(tower: "Diamond", createdAt: daysAfter(tuesday, 7), itemName: item.name, pieces: 220),
        ]

        let predictions = service.predictions(
            towerName: "Diamond",
            items: [item],
            logs: logs,
            referenceDate: referenceMonday
        )

        let prediction = try XCTUnwrap(predictions.first)
        XCTAssertEqual(prediction.predictedPieces, 90, "Should median Monday-only samples (80, 100), not Tuesdays.")
        XCTAssertEqual(prediction.sameWeekdaySampleCount, 2)
        XCTAssertNotEqual(prediction.predictedPieces, 210, "Should not blend in Tuesday samples (200, 220).")
        XCTAssertEqual(prediction.confidence, .low)
    }

    func test_predictions_usesBinsForFixedBinItems() throws {
        let item = makeItem(name: "Bath Towel", countMethod: .fixedBin, piecesPerBin: 245)
        let logs = [
            makeLog(tower: "Lagoon", createdAt: daysBefore(referenceMonday, 3), itemName: item.name, bins: 2),
            makeLog(tower: "Lagoon", createdAt: daysBefore(referenceMonday, 10), itemName: item.name, bins: 4),
        ]

        let predictions = service.predictions(
            towerName: "Lagoon",
            items: [item],
            logs: logs,
            referenceDate: referenceMonday
        )

        let prediction = try XCTUnwrap(predictions.first)
        XCTAssertNil(prediction.predictedPieces)
        XCTAssertEqual(prediction.predictedBins, 3)
    }

    // MARK: - Anomalies

    func test_anomalies_flagsUnusuallyHighEntry() {
        let predictions = [
            ItemSupplyPrediction(
                itemName: "King Sheet",
                predictedPieces: 100,
                predictedBins: nil,
                sampleCount: 4,
                sameWeekdaySampleCount: 0,
                confidence: .medium,
                typicalLabel: "Typical"
            ),
        ]
        let entries = [
            ReceivingEntry(
                itemName: "King Sheet",
                countMethod: .manualPieces,
                manualPieces: 160,
                calculatedPieces: 160
            ),
        ]

        let anomalies = service.anomalies(entries: entries, predictions: predictions)

        XCTAssertEqual(anomalies.count, 1)
        XCTAssertEqual(anomalies.first?.direction, .unusuallyHigh)
        XCTAssertEqual(anomalies.first?.enteredValue, 160)
        XCTAssertEqual(anomalies.first?.typicalValue, 100)
    }

    func test_anomalies_flagsUnusuallyLowEntry() {
        let predictions = [
            ItemSupplyPrediction(
                itemName: "King Sheet",
                predictedPieces: 100,
                predictedBins: nil,
                sampleCount: 3,
                sameWeekdaySampleCount: 0,
                confidence: .medium,
                typicalLabel: "Typical"
            ),
        ]
        let entries = [
            ReceivingEntry(
                itemName: "King Sheet",
                countMethod: .manualPieces,
                manualPieces: 50,
                calculatedPieces: 50
            ),
        ]

        let anomalies = service.anomalies(entries: entries, predictions: predictions)

        XCTAssertEqual(anomalies.count, 1)
        XCTAssertEqual(anomalies.first?.direction, .unusuallyLow)
    }

    func test_anomalies_ignoresSmallDeviation() {
        let predictions = [
            ItemSupplyPrediction(
                itemName: "King Sheet",
                predictedPieces: 100,
                predictedBins: nil,
                sampleCount: 5,
                sameWeekdaySampleCount: 0,
                confidence: .medium,
                typicalLabel: "Typical"
            ),
        ]
        let entries = [
            ReceivingEntry(
                itemName: "King Sheet",
                countMethod: .manualPieces,
                manualPieces: 110,
                calculatedPieces: 110
            ),
        ]

        XCTAssertTrue(service.anomalies(entries: entries, predictions: predictions).isEmpty)
    }

    // MARK: - Recommendations

    func test_recommendations_detectsRecurringShortage() {
        let logs = (0..<4).map { offset in
            makeLogWithSummary(
                tower: "Diamond",
                createdAt: daysBefore(referenceMonday, offset),
                itemName: "Bath Towel",
                status: .shortage,
                receivedPieces: 5
            )
        }

        let recommendations = service.recommendations(logs: logs, towerFilter: "Diamond")

        XCTAssertTrue(
            recommendations.contains { $0.title == "Recurring Bath Towel shortage" && $0.severity == .action }
        )
    }

    func test_recommendations_filtersByTower() {
        let diamondLogs = (0..<3).map { offset in
            makeLogWithSummary(
                tower: "Diamond",
                createdAt: daysBefore(referenceMonday, offset),
                itemName: "Hand Towel",
                status: .shortage,
                receivedPieces: 1
            )
        }
        let lagoonStable = makeLogWithSummary(
            tower: "Lagoon",
            createdAt: daysBefore(referenceMonday, 1),
            itemName: "Hand Towel",
            status: .exact,
            receivedPieces: 100
        )

        let recommendations = service.recommendations(logs: diamondLogs + [lagoonStable], towerFilter: "Diamond")

        XCTAssertTrue(recommendations.contains { $0.itemName == "Hand Towel" })
        XCTAssertFalse(recommendations.contains { $0.detail.localizedCaseInsensitiveContains("Lagoon") && $0.severity == .action })
    }

    // MARK: - Helpers

    private func makeItem(
        name: String,
        countMethod: CountMethod,
        piecesPerBin: Int? = nil
    ) -> LinenItem {
        LinenItem(
            name: name,
            parCount: 4,
            countMethod: countMethod,
            bundleSize: 5,
            piecesPerBin: piecesPerBin
        )
    }

    private func makeLog(
        tower: String,
        createdAt: Date,
        itemName: String,
        pieces: Int? = nil,
        bins: Int? = nil
    ) -> DailyLog {
        let entry: ReceivingEntry
        if let bins {
            entry = ReceivingEntry(
                itemName: itemName,
                countMethod: .fixedBin,
                binCount: bins,
                piecesPerBin: 245,
                calculatedPieces: bins * 245
            )
        } else {
            entry = ReceivingEntry(
                itemName: itemName,
                countMethod: .manualPieces,
                manualPieces: pieces,
                calculatedPieces: pieces ?? 0
            )
        }

        return DailyLog(
            date: createdAt,
            towerName: tower,
            floorCount: 15,
            entriesSnapshot: [entry],
            summarySnapshot: [],
            distributionSnapshot: [],
            createdAt: createdAt
        )
    }

    private func makeLogWithSummary(
        tower: String,
        createdAt: Date,
        itemName: String,
        status: CalculationStatus,
        receivedPieces: Int
    ) -> DailyLog {
        let summary = CalculationSummary(
            itemName: itemName,
            receivedPieces: receivedPieces,
            bundleSize: 5,
            fullBundles: 0,
            loosePieces: 0,
            requiredPieces: 50,
            differencePieces: receivedPieces - 50,
            status: status,
            exactPerFloorPieces: 3,
            basePerFloorPieces: 3,
            remainderPieces: 0
        )
        return DailyLog(
            date: createdAt,
            towerName: tower,
            floorCount: 15,
            entriesSnapshot: [],
            summarySnapshot: [summary],
            distributionSnapshot: [],
            createdAt: createdAt
        )
    }

    private func daysBefore(_ date: Date, _ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: date)!
    }

    private func daysAfter(_ date: Date, _ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }
}
