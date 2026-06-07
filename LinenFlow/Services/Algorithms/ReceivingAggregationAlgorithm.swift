import Foundation

struct AggregatedReceivingRow {
    let itemName: String
    let totalPieces: Int
    let sourceEntryCount: Int
    let notesSummary: String?
}

enum ReceivingAggregationAlgorithm {
    /// Aggregates receiving entries by canonical item name, summing calculatedPieces.
    /// Entries with empty names are ignored. Returns rows sorted alphabetically by itemName.
    static func aggregate(_ entries: [ReceivingEntry]) -> [AggregatedReceivingRow] {
        var groups: [String: [ReceivingEntry]] = [:]
        for entry in entries where !entry.itemName.isEmpty {
            let key = BundleLibrary.canonicalName(for: entry.itemName)
            groups[key, default: []].append(entry)
        }
        return groups.map { name, rows in
            let totalPieces = rows.reduce(0) { $0 + $1.calculatedPieces }
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
}
