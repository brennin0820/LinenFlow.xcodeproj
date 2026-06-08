import Foundation

struct SmartRebalanceEngine: Sendable {
    func suggestions(
        summaries: [CalculationSummary],
        deliveryRows: [FloorDistributionRow],
        deliveryUnitIsBundles: Bool = false
    ) -> [RebalanceSuggestion] {
        summaries
            .filter { $0.status == .shortage && $0.differencePieces < 0 }
            .compactMap { summary in
                suggestion(
                    for: summary,
                    rows: deliveryRows.filter { $0.itemName == summary.itemName },
                    deliveryUnitIsBundles: deliveryUnitIsBundles
                )
            }
    }

    private func suggestion(
        for summary: CalculationSummary,
        rows: [FloorDistributionRow],
        deliveryUnitIsBundles: Bool
    ) -> RebalanceSuggestion? {
        guard !rows.isEmpty else { return nil }
        let shortagePieces = abs(summary.differencePieces)
        let basePerFloor = basePerFloorDelivery(for: summary, rows: rows, deliveryUnitIsBundles: deliveryUnitIsBundles)
        let sortedRows = rows.sorted { $0.floorNumber < $1.floorNumber }
        let targetFloors = sortedRows
            .filter { deliveryValue($0, deliveryUnitIsBundles: deliveryUnitIsBundles) < basePerFloor }
            .map(\.floorNumber)
        let donorFloors = sortedRows
            .filter { deliveryValue($0, deliveryUnitIsBundles: deliveryUnitIsBundles) > basePerFloor }
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

    private func basePerFloorDelivery(
        for summary: CalculationSummary,
        rows: [FloorDistributionRow],
        deliveryUnitIsBundles: Bool
    ) -> Int {
        guard !rows.isEmpty else { return 0 }
        if deliveryUnitIsBundles {
            return summary.deliverableBundles / rows.count
        }
        return summary.basePerFloorPieces
    }

    private func deliveryValue(_ row: FloorDistributionRow, deliveryUnitIsBundles: Bool) -> Int {
        if deliveryUnitIsBundles {
            return row.suggestedBundles ?? row.suggestedPieces
        }
        return row.suggestedPieces
    }

    private func pieceLabel(for itemName: String, count: Int) -> String {
        count == 1 ? itemName.lowercased() : "\(itemName.lowercased())s"
    }
}
