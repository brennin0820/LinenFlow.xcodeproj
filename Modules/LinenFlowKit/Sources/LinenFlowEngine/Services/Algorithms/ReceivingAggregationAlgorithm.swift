import Foundation
import LinenFlowCore

public struct AggregatedReceivingRow {
    public let itemName: String
    public let totalPieces: Int
    public let sourceEntryCount: Int
    public let notesSummary: String?
}

public enum ReceivingAggregationAlgorithm {
    /// Aggregates receiving entries by canonical item name, summing received pieces.
    /// Pieces are derived from each entry's count method (not stale stored `calculatedPieces`).
    /// Entries with empty names are ignored. Returns rows sorted alphabetically by itemName.
    public static func aggregate(_ entries: [ReceivingEntry]) -> [AggregatedReceivingRow] {
        var groups: [String: [ReceivingEntry]] = [:]
        for entry in entries where !entry.itemName.isEmpty {
            let key = BundleLibrary.canonicalName(for: entry.itemName)
            groups[key, default: []].append(entry)
        }
        return groups.map { name, rows in
            let totalPieces = rows.reduce(0) { $0 + receivedPieces(for: $1) }
            let noteParts = rows.compactMap(\.notes).filter { !$0.isEmpty }
            return AggregatedReceivingRow(
                itemName: name,
                totalPieces: totalPieces,
                sourceEntryCount: rows.count,
                notesSummary: noteParts.isEmpty ? nil : noteParts.joined(separator: ", ")
            )
        }
        .sorted { $0.itemName < $1.itemName }
    }

    /// Prefer count-method derivation; fall back to stored `calculatedPieces` for legacy snapshots.
    private static func receivedPieces(for entry: ReceivingEntry) -> Int {
        let derived = LinenCalculatorService.calculateReceivedPieces(entry: entry)
        let hasCountMethodInput: Bool
        switch entry.countMethod {
        case .fixedBin:
            hasCountMethodInput = entry.binCount != nil
        case .manualPieces, .cartLabelPieces:
            hasCountMethodInput = entry.manualPieces != nil
        }
        return hasCountMethodInput ? derived : max(0, entry.calculatedPieces)
    }
}
