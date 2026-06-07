import Foundation

struct ElevatorTripPlan: Hashable, Sendable {
    var trips: [ElevatorTrip]
    var completedTripIDs: Set<UUID>

    var totalTrips: Int { trips.count }
    var remainingTrips: Int { trips.filter { !completedTripIDs.contains($0.id) }.count }
    var nextTrip: ElevatorTrip? { trips.first { !completedTripIDs.contains($0.id) } }
    var efficiencyText: String {
        guard totalTrips > 0 else { return "No elevator trips needed yet." }
        return remainingTrips == 0 ? "All planned elevator trips are complete." : "\(remainingTrips) of \(totalTrips) trips remaining."
    }
}

struct ElevatorTripPlanner: Sendable {
    func plan(
        summaries: [CalculationSummary],
        entries: [ReceivingEntry],
        completedTripIDs: Set<UUID> = []
    ) -> ElevatorTripPlan {
        var loads = makeLoads(summaries: summaries, entries: entries)
        var trips: [ElevatorTrip] = []
        var sequence = 1

        while !loads.isEmpty {
            let first = loads.removeFirst()
            let secondIndex = loads.firstIndex { $0.itemName != first.itemName }
            let second: Load?
            if let secondIndex {
                second = loads.remove(at: secondIndex)
            } else if !loads.isEmpty {
                second = loads.removeFirst()
            } else {
                second = nil
            }

            let estimatedBundles = first.bundleCount + (second?.bundleCount ?? 0)
            let note: String
            if let second {
                note = "\(first.itemName) (\(first.bundleCount) bdl) + \(second.itemName) (\(second.bundleCount) bdl)"
            } else {
                note = "\(first.itemName) — final trip (\(first.bundleCount) bdl)"
            }
            trips.append(ElevatorTrip(
                sequence: sequence,
                primaryItemName: first.itemName,
                secondaryItemName: second?.itemName,
                estimatedBundles: estimatedBundles,
                strategyNote: note
            ))
            sequence += 1
        }

        return ElevatorTripPlan(trips: trips, completedTripIDs: completedTripIDs)
    }

    private func makeLoads(summaries: [CalculationSummary], entries: [ReceivingEntry]) -> [Load] {
        summaries
            .filter { $0.fullBundles > 0 || $0.receivedPieces > 0 }
            .flatMap { summary in
                let loadCount = logisticalLoadCount(for: summary, entries: entries)
                return (0..<loadCount).map { index in
                    Load(
                        itemName: loadName(for: summary.itemName, index: index, count: loadCount),
                        baseItemName: summary.itemName,
                        bundleCount: max(1, Int(ceil(Double(max(summary.fullBundles, 1)) / Double(loadCount))))
                    )
                }
            }
            .sorted { lhs, rhs in
                if priority(lhs.baseItemName) == priority(rhs.baseItemName) {
                    return lhs.itemName < rhs.itemName
                }
                return priority(lhs.baseItemName) < priority(rhs.baseItemName)
            }
    }

    private func logisticalLoadCount(for summary: CalculationSummary, entries: [ReceivingEntry]) -> Int {
        let matchingEntries = entries.filter { $0.itemName == summary.itemName }
        // Fixed-bin items use their bin count.
        let fixedBins = matchingEntries.compactMap(\.binCount).reduce(0, +)
        if fixedBins > 0 { return min(max(fixedBins, 1), 8) }
        // Manual items with a physical bin count use that for trip planning.
        let physicalBins = matchingEntries.compactMap(\.physicalBinCount).reduce(0, +)
        if physicalBins > 0 { return min(max(physicalBins, 1), 8) }
        return min(max(Int(ceil(Double(max(summary.fullBundles, 1)) / 24.0)), 1), 8)
    }

    private func loadName(for itemName: String, index: Int, count: Int) -> String {
        guard count > 1 else { return itemName }
        let suffix = Character(UnicodeScalar(65 + min(index, 25))!)
        return "\(itemName) Bin \(suffix)"
    }

    private func priority(_ itemName: String) -> Int {
        let name = itemName.lowercased()
        if name.contains("washcloth") { return 0 }
        if name.contains("hand towel") { return 1 }
        if name.contains("bath mat") { return 2 }
        if name.contains("pillow") { return 3 }
        if name.contains("bath towel") { return 4 }
        return 8
    }

    private struct Load: Hashable {
        var itemName: String
        var baseItemName: String
        var bundleCount: Int
    }
}
