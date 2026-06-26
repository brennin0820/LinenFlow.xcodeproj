import Foundation
import LinenFlowCore

public struct CarryGroupBuilder: Sendable {
    public func build(entries: [ReceivingEntry], summaries: [CalculationSummary]) -> [CarryGroup] {
        let summariesByName = Dictionary(uniqueKeysWithValues: summaries.map { ($0.itemName, $0) })
        var groups: [CarryGroup] = []

        for entry in entries where isBathTowel(entry.itemName) {
            let binCount = max(0, entry.binCount ?? 0)
            guard binCount > 0 else { continue }
            for index in 1...binCount {
                groups.append(CarryGroup(
                    itemName: entry.itemName,
                    label: "\(entry.itemName) Bin \(index)",
                    carryType: .physicalBin,
                    count: 1,
                    estimatedWeightClass: estimatedWeightClass(for: entry.itemName),
                    sourceEntryID: entry.id
                ))
            }
        }

        let nonBathEntriesByName = Dictionary(grouping: entries.filter { !isBathTowel($0.itemName) }, by: \.itemName)
        for itemName in nonBathEntriesByName.keys.sorted() {
            let itemEntries = nonBathEntriesByName[itemName] ?? []
            let physicalGroups = physicalBinGroups(for: itemEntries)
            if !physicalGroups.isEmpty {
                groups.append(contentsOf: physicalGroups)
                continue
            }

            guard let summary = summariesByName[itemName] else { continue }
            if summary.fullBundles > 0 {
                groups.append(CarryGroup(
                    itemName: itemName,
                    label: "\(itemName) Bundle Group",
                    carryType: .bundleGroup,
                    count: summary.fullBundles,
                    estimatedWeightClass: estimatedWeightClass(for: itemName),
                    sourceEntryID: itemEntries.first?.id
                ))
            } else if summary.loosePieces > 0 {
                groups.append(CarryGroup(
                    itemName: itemName,
                    label: "\(itemName) Loose Carry",
                    carryType: .looseCarry,
                    count: summary.loosePieces,
                    estimatedWeightClass: estimatedWeightClass(for: itemName),
                    sourceEntryID: itemEntries.first?.id
                ))
            }
        }

        return groups.sorted { lhs, rhs in
            if weightPriority(lhs.estimatedWeightClass) == weightPriority(rhs.estimatedWeightClass) {
                return lhs.label < rhs.label
            }
            return weightPriority(lhs.estimatedWeightClass) < weightPriority(rhs.estimatedWeightClass)
        }
    }

    private func physicalBinGroups(for entries: [ReceivingEntry]) -> [CarryGroup] {
        var groups: [CarryGroup] = []
        var itemBinIndex: [String: Int] = [:]

        for entry in entries {
            let binCount = max(0, entry.physicalBinCount ?? 0)
            guard binCount > 0 else { continue }
            for _ in 0..<binCount {
                let nextIndex = (itemBinIndex[entry.itemName] ?? 0) + 1
                itemBinIndex[entry.itemName] = nextIndex
                groups.append(CarryGroup(
                    itemName: entry.itemName,
                    label: "\(entry.itemName) Bin \(nextIndex)",
                    carryType: .physicalBin,
                    count: 1,
                    estimatedWeightClass: estimatedWeightClass(for: entry.itemName),
                    sourceEntryID: entry.id
                ))
            }
        }

        return groups
    }

    private func isBathTowel(_ itemName: String) -> Bool {
        itemName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "bath towel"
    }

    private func estimatedWeightClass(for itemName: String) -> EstimatedWeightClass {
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["washcloth", "bath mat", "pillow case"].contains(name) {
            return .light
        }
        if ["hand towel", "queen sheet", "queen cover", "double sheet", "double cover"].contains(name) {
            return .medium
        }
        return .heavy
    }

    private func weightPriority(_ weightClass: EstimatedWeightClass) -> Int {
        switch weightClass {
        case .light: return 0
        case .medium: return 1
        case .heavy: return 2
        }
    }
}
