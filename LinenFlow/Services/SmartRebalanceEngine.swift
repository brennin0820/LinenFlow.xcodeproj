import Foundation

struct SmartRebalanceEngine: Sendable {
    func suggestions(
        summaries: [CalculationSummary],
        deliveryRows: [FloorDistributionRow]
    ) -> [RebalanceSuggestion] {
        summaries
            .filter { $0.status == .shortage && $0.differencePieces < 0 }
            .compactMap { summary in
                suggestion(for: summary, rows: deliveryRows.filter { $0.itemName == summary.itemName })
            }
    }

    private func suggestion(for summary: CalculationSummary, rows: [FloorDistributionRow]) -> RebalanceSuggestion? {
        guard !rows.isEmpty else { return nil }
        let shortagePieces = abs(summary.differencePieces)
        let sortedRows = rows.sorted { $0.floorNumber < $1.floorNumber }
        let targetFloors = sortedRows
            .filter { deliveryValue($0) < summary.basePerFloorPieces }
            .map(\.floorNumber)
        let donorFloors = sortedRows
            .filter { deliveryValue($0) > summary.basePerFloorPieces }
            .map(\.floorNumber)
            .prefix(shortagePieces)
            .map { $0 }

        guard !donorFloors.isEmpty else {
            return RebalanceSuggestion(
                itemName: summary.itemName,
                message: "No safe donor floors found for \(summary.itemName).",
                donorFloors: [],
                targetFloors: targetFloors,
                piecesRecovered: 0,
                isRecoverable: false
            )
        }

        let recovered = min(shortagePieces, donorFloors.count)
        let floorText = donorFloors.map(String.init).joined(separator: ", ")
        let message = "Collect 1 \(pieceLabel(for: summary.itemName, count: 1)) from Floors \(floorText)."

        return RebalanceSuggestion(
            itemName: summary.itemName,
            message: message,
            donorFloors: donorFloors,
            targetFloors: targetFloors,
            piecesRecovered: recovered,
            isRecoverable: recovered == shortagePieces
        )
    }

    private func deliveryValue(_ row: FloorDistributionRow) -> Int {
        if let bundles = row.suggestedBundles, bundles > 0 { return bundles }
        return row.suggestedPieces
    }

    private func pieceLabel(for itemName: String, count: Int) -> String {
        count == 1 ? itemName.lowercased() : "\(itemName.lowercased())s"
    }
}
