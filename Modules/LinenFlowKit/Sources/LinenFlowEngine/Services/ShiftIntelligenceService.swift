import Foundation
import LinenFlowCore

/// On-device intelligence from saved daily logs: predictions, anomalies, and recommendations.
public struct ShiftIntelligenceService: Sendable {
    private let calendar: Calendar
    private let minimumSamplesForPrediction = 2
    private let minimumSamplesForAnomaly = 3

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Predictions

    public func predictions(
        towerName: String,
        items: [LinenItem],
        logs: [DailyLog],
        referenceDate: Date = .now
    ) -> [ItemSupplyPrediction] {
        let towerLogs = logs.filter { $0.towerName == towerName }
        guard !towerLogs.isEmpty else { return [] }

        let weekday = calendar.component(.weekday, from: referenceDate)
        let weekdayLogs = towerLogs.filter { calendar.component(.weekday, from: $0.createdAt) == weekday }
        let weekdayName = referenceDate.formatted(.dateTime.weekday(.wide))

        return items.compactMap { item in
            let weekdaySamples = sampleValues(for: item, in: weekdayLogs)
            let allSamples = sampleValues(for: item, in: towerLogs)
            let samples = weekdaySamples.count >= minimumSamplesForPrediction ? weekdaySamples : allSamples
            let sameWeekdayCount = weekdaySamples.count
            guard samples.count >= minimumSamplesForPrediction else { return nil }

            let typical = median(samples)
            guard typical > 0 else { return nil }

            let confidence = confidenceLevel(sampleCount: samples.count, prefersWeekday: weekdaySamples.count >= minimumSamplesForPrediction)
            let usesBins = item.countMethod == .fixedBin
            let typicalLabel: String
            if weekdaySamples.count >= minimumSamplesForPrediction {
                typicalLabel = "Typical \(weekdayName) for \(towerName)"
            } else {
                typicalLabel = "Typical for \(towerName)"
            }

            return ItemSupplyPrediction(
                itemName: item.name,
                predictedPieces: usesBins ? nil : typical,
                predictedBins: usesBins ? typical : nil,
                sampleCount: samples.count,
                sameWeekdaySampleCount: sameWeekdayCount,
                confidence: confidence,
                typicalLabel: typicalLabel
            )
        }
    }

    // MARK: - Anomalies

    public func anomalies(
        entries: [ReceivingEntry],
        predictions: [ItemSupplyPrediction]
    ) -> [SupplyAnomaly] {
        let predictionByItem = Dictionary(uniqueKeysWithValues: predictions.map { ($0.itemName, $0) })

        return entries.compactMap { entry in
            guard let prediction = predictionByItem[entry.itemName],
                  prediction.sampleCount >= minimumSamplesForAnomaly else {
                return nil
            }

            let (entered, unitLabel, typical) = enteredAndTypical(for: entry, prediction: prediction)
            guard entered > 0, typical > 0 else { return nil }

            let deviation = abs(Double(entered - typical)) / Double(typical)
            let threshold = max(0.25, relativeAnomalyThreshold(for: typical))
            guard deviation >= threshold else { return nil }

            return SupplyAnomaly(
                itemName: entry.itemName,
                enteredValue: entered,
                typicalValue: typical,
                unitLabel: unitLabel,
                direction: entered < typical ? .unusuallyLow : .unusuallyHigh,
                sampleCount: prediction.sampleCount
            )
        }
    }

    // MARK: - Recommendations

    public func recommendations(
        logs: [DailyLog],
        towerFilter: String?
    ) -> [SupplyRecommendation] {
        let filtered = towerFilter.map { filter in
            logs.filter { $0.towerName == filter }
        } ?? logs

        guard filtered.count >= 3 else { return [] }

        var results: [SupplyRecommendation] = []
        let recent = Array(filtered.suffix(14))
        let itemNames = Set(recent.flatMap { $0.summarySnapshot.map(\.itemName) })

        for itemName in itemNames.sorted() {
            let summaries = recent.compactMap { log in
                log.summarySnapshot.first { $0.itemName == itemName }
            }
            guard summaries.count >= 3 else { continue }

            let shortageCount = summaries.filter { $0.status == .shortage }.count
            let shortageRate = Double(shortageCount) / Double(summaries.count)

            if shortageCount >= 3 && shortageRate >= 0.5 {
                let towerLabel = towerFilter ?? summariesTowerHint(from: recent, itemName: itemName)
                results.append(
                    SupplyRecommendation(
                        towerName: towerLabel,
                        itemName: itemName,
                        title: "Recurring \(itemName) shortage",
                        detail: "Short on \(shortageCount) of the last \(summaries.count) logs. Consider staging extra supply before the shift.",
                        severity: .action
                    )
                )
            }

            let receivedValues = summaries.map(\.receivedPieces).filter { $0 > 0 }
            if receivedValues.count >= 4 {
                let recentHalf = Array(receivedValues.suffix(receivedValues.count / 2))
                let earlierHalf = Array(receivedValues.prefix(receivedValues.count / 2))
                let recentAvg = average(recentHalf)
                let earlierAvg = average(earlierHalf)
                if earlierAvg > 0, recentAvg < earlierAvg * 0.85 {
                    let dropPercent = Int((1 - recentAvg / earlierAvg) * 100)
                    results.append(
                        SupplyRecommendation(
                            towerName: towerFilter,
                            itemName: itemName,
                            title: "\(itemName) supply trending down",
                            detail: "Received amounts dropped about \(dropPercent)% compared to earlier logs. Verify counts at receiving.",
                            severity: .caution
                        )
                    )
                }
            }
        }

        if results.isEmpty, let bestTower = mostConsistentTower(in: filtered) {
            results.append(
                SupplyRecommendation(
                    towerName: bestTower,
                    itemName: nil,
                    title: "Supply looks stable",
                    detail: "\(bestTower) has had no recurring shortages in recent logs. Current par levels appear well matched.",
                    severity: .info
                )
            )
        }

        return results.sorted { lhs, rhs in
            severityRank(lhs.severity) > severityRank(rhs.severity)
        }
    }

    // MARK: - Helpers

    private func sampleValues(for item: LinenItem, in logs: [DailyLog]) -> [Int] {
        logs.compactMap { log in
            guard let entry = log.entriesSnapshot.first(where: { $0.itemName == item.name }) else {
                return nil
            }
            switch item.countMethod {
            case .fixedBin:
                return entry.binCount ?? entry.physicalBinCount
            case .manualPieces, .cartLabelPieces:
                return entry.calculatedPieces > 0 ? entry.calculatedPieces : entry.manualPieces
            }
        }
        .compactMap { $0 }
        .filter { $0 > 0 }
    }

    private func enteredAndTypical(
        for entry: ReceivingEntry,
        prediction: ItemSupplyPrediction
    ) -> (entered: Int, unitLabel: String, typical: Int) {
        if let bins = prediction.predictedBins {
            let entered = entry.binCount ?? entry.physicalBinCount ?? 0
            return (entered, "bins", bins)
        }
        let entered = entry.calculatedPieces > 0 ? entry.calculatedPieces : (entry.manualPieces ?? 0)
        return (entered, "pcs", prediction.predictedPieces ?? 0)
    }

    private func relativeAnomalyThreshold(for typical: Int) -> Double {
        typical <= 10 ? 0.35 : 0.25
    }

    private func confidenceLevel(sampleCount: Int, prefersWeekday: Bool) -> PredictionConfidence {
        if sampleCount >= 8 && prefersWeekday { return .high }
        if sampleCount >= 4 { return .medium }
        return .low
    }

    private func median(_ values: [Int]) -> Int {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }

    private func average(_ values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    private func severityRank(_ severity: RecommendationSeverity) -> Int {
        switch severity {
        case .action: return 3
        case .caution: return 2
        case .info: return 1
        }
    }

    private func summariesTowerHint(from logs: [DailyLog], itemName: String) -> String? {
        let towers = logs.compactMap { log -> String? in
            log.summarySnapshot.contains { $0.itemName == itemName && $0.status == .shortage } ? log.towerName : nil
        }
        let counts = Dictionary(grouping: towers, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func mostConsistentTower(in logs: [DailyLog]) -> String? {
        let recent = Array(logs.suffix(10))
        let towers = Set(recent.map(\.towerName))
        return towers.first { tower in
            let towerLogs = recent.filter { $0.towerName == tower }
            guard towerLogs.count >= 3 else { return false }
            return !towerLogs.contains { log in
                log.summarySnapshot.contains { $0.status == .shortage }
            }
        }
    }
}
