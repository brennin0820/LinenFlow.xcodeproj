import Foundation
import LinenFlowCore

public enum DailyReportService {
    public static func makeShareText(from log: DailyLog) -> String {
        var lines: [String] = []
        let dateText = log.date.formatted(date: .abbreviated, time: .omitted)
        let savedText = log.createdAt.formatted(date: .abbreviated, time: .shortened)
        let totalReceivedPieces = log.entriesSnapshot.reduce(0) { $0 + $1.calculatedPieces }
        let totalRequiredPieces = log.summarySnapshot.reduce(0) { $0 + $1.requiredPieces }
        let totalDifferencePieces = log.summarySnapshot.reduce(0) { $0 + $1.differencePieces }

        lines.append("HimmerFlow Daily Report")
        lines.append("========================")
        lines.append("Tower: \(log.towerName)")
        lines.append("Date: \(dateText)")
        lines.append("Saved: \(savedText)")
        lines.append("Floors: \(log.floorCount)")
        lines.append("")
        lines.append("Received: \(totalReceivedPieces) pcs")
        lines.append("Required: \(totalRequiredPieces) pcs")
        lines.append("Net: \(signed(totalDifferencePieces)) pcs")

        if !log.summarySnapshot.isEmpty {
            lines.append("")
            lines.append("Item Summary")
            for summary in log.summarySnapshot.sorted(by: { $0.itemName < $1.itemName }) {
                lines.append(summaryLine(summary))
            }
        }

        let unitIsBundles = log.distributionSnapshot.contains {
            ($0.suggestedBundles ?? 0) > 0 && $0.suggestedPieces == 0
        }
        let groups = FloorRangeBuilder.build(from: log.distributionSnapshot, unitIsBundles: unitIsBundles)
        if !groups.isEmpty {
            lines.append("")
            lines.append("Floor Plan")
            for group in groups.sorted(by: { $0.itemName < $1.itemName }) {
                let ranges = group.ranges
                    .map { "\(floorLabel($0)): \(valueLabel($0.suggestedValue, unitIsBundles: group.unitIsBundles))" }
                    .joined(separator: "; ")
                lines.append("- \(group.itemName): \(ranges)")
            }
        }

        if !log.entriesSnapshot.isEmpty {
            lines.append("")
            lines.append("Receiving")
            let sortedEntries = log.entriesSnapshot.sorted(by: { $0.itemName < $1.itemName })
            for entry in sortedEntries {
                lines.append(entryLine(entry))
            }
            let totalPieces = sortedEntries.reduce(0) { $0 + $1.calculatedPieces }
            lines.append("  Total: \(totalPieces) pcs from \(sortedEntries.count) items")
        }

        let notes = log.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty {
            lines.append("")
            lines.append("Notes")
            lines.append(notes)
        }

        return lines.joined(separator: "\n")
    }

    private static func summaryLine(_ summary: CalculationSummary) -> String {
        let statusTag: String
        switch summary.status {
        case .shortage: statusTag = "[SHORT]"
        case .overage:  statusTag = "[OVER]"
        case .exact:    statusTag = "[EXACT]"
        }
        let difference = signed(summary.differencePieces)
        return "- \(summary.itemName) \(statusTag): \(summary.fullBundles) bdl (\(summary.bundleSize)/bdl), \(summary.loosePieces) loose, deliver \(summary.deliverableBundles) bdl, net \(difference) pcs"
    }

    private static func entryLine(_ entry: ReceivingEntry) -> String {
        let method: String
        switch entry.countMethod {
        case .fixedBin:
            method = "\(entry.binCount ?? 0) bins x \(entry.piecesPerBin ?? 0) pcs"
        case .manualPieces:
            method = "manual \(entry.manualPieces ?? 0) pcs"
        case .cartLabelPieces:
            method = [entry.notes, "cart/label \(entry.manualPieces ?? 0) pcs"]
                .compactMap { $0 }
                .joined(separator: " - ")
        }
        return "- \(entry.itemName): \(method), total \(entry.calculatedPieces) pcs"
    }

    private static func valueLabel(_ value: Int, unitIsBundles: Bool) -> String {
        if unitIsBundles {
            return value == 1 ? "1 bundle" : "\(value) bundles"
        }
        return "\(value) pcs"
    }

    private static func floorLabel(_ range: FloorRange) -> String {
        range.firstFloor == range.lastFloor
            ? "Floor \(range.firstFloor)"
            : "Floors \(range.firstFloor)-\(range.lastFloor)"
    }

    private static func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
