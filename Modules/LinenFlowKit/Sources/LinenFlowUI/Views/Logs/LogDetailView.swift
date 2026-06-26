import SwiftUI
import SwiftData
import OSLog
import LinenFlowCore
import LinenFlowEngine

public struct LogDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    public let log: DailyLog
    @State private var expandedItemNames: Set<String> = []

    public var body: some View {
        AppBackground {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    reportSnapshotCard

                    logSection(title: "Received entries", isEmpty: log.entriesSnapshot.isEmpty) {
                        ForEach(log.entriesSnapshot) { entry in
                            EntryRow(entry: entry)
                        }
                    }

                    logSection(title: "Item summaries", isEmpty: itemSummaries.isEmpty) {
                        ForEach(itemSummaries) { itemSummary in
                            ExpandableLogItemSummaryRow(
                                itemSummary: itemSummary,
                                isExpanded: expandedItemNames.contains(itemSummary.itemName)
                            ) {
                                withAnimation(.snappy(duration: 0.18)) {
                                    toggleItemSummary(itemSummary.itemName)
                                }
                            }
                        }
                    }

                    if !log.notes.isEmpty {
                        SectionHeader(title: "Notes")
                        PremiumCard {
                            Text(log.notes)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("Log Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: reportShareText) {
                        Label("Share as Text", systemImage: "doc.plaintext")
                    }
                    if let csvURL = CSVExportService.generateCSV(for: log) {
                        ShareLink(item: csvURL) {
                            Label("Export as CSV", systemImage: "tablecells")
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share daily report")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        modelContext.delete(log)
                        do {
                            try modelContext.save()
                        } catch {
                            AppLogger.logs.error("Log detail delete save failed: \(error, privacy: .public)")
                        }
                        dismiss()
                    } label: {
                        Label("Delete log", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var headerCard: some View {
        PremiumCard(accentColor: DefaultData.towers.first(where: { $0.name == log.towerName })
            .flatMap { Color(hex: $0.identityColorHex ?? "") }) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.towerName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(log.date.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                    Text("\(log.floorCount) floors · saved \(log.createdAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(totalReceivedPieces)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("pcs received")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
    }

    private var reportSnapshotCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Report snapshot")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(statusSummary)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusTint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusTint.opacity(0.16), in: Capsule())
                }

                HStack(spacing: 8) {
                    snapshotFact("Items", "\(log.entriesSnapshot.count)")
                    snapshotFact("Required", "\(totalRequiredPieces)")
                    snapshotFact("Net", signed(totalDifferencePieces))
                }
            }
        }
    }

    private func logSection<Content: View>(
        title: String,
        isEmpty: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            if isEmpty {
                EmptyStateView(
                    systemImage: "doc.text.magnifyingglass",
                    title: "No saved \(title.lowercased())",
                    message: "This log does not include data for this section."
                )
            } else {
                content()
            }
        }
    }

    private var itemSummaries: [LogItemSummary] {
        let unitIsBundles = log.distributionSnapshot.contains {
            ($0.suggestedBundles ?? 0) > 0 && $0.suggestedPieces == 0
        }
        let distributionByItem = Dictionary(
            uniqueKeysWithValues: FloorRangeBuilder
                .build(from: log.distributionSnapshot, unitIsBundles: unitIsBundles)
                .map { ($0.itemName, $0) }
        )
        let entriesByItem = Dictionary(grouping: log.entriesSnapshot, by: \.itemName)

        return log.summarySnapshot
            .map { summary in
                LogItemSummary(
                    summary: summary,
                    entries: entriesByItem[summary.itemName] ?? [],
                    distributionGroup: distributionByItem[summary.itemName]
                )
            }
            .sorted { $0.itemName < $1.itemName }
    }

    private func toggleItemSummary(_ itemName: String) {
        if expandedItemNames.contains(itemName) {
            expandedItemNames.remove(itemName)
        } else {
            expandedItemNames.insert(itemName)
        }
    }

    private var reportShareText: String {
        DailyReportService.makeShareText(from: log)
    }

    private func snapshotFact(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
    }

    private var totalReceivedPieces: Int {
        log.entriesSnapshot.reduce(0) { $0 + $1.calculatedPieces }
    }

    private var totalRequiredPieces: Int {
        log.summarySnapshot.reduce(0) { $0 + $1.requiredPieces }
    }

    private var totalDifferencePieces: Int {
        log.summarySnapshot.reduce(0) { $0 + $1.differencePieces }
    }

    private var statusSummary: String {
        let summaries = log.summarySnapshot
        guard !summaries.isEmpty else { return "No totals" }
        if summaries.contains(where: { $0.status == .shortage }) {
            return "Needs review"
        }
        if summaries.contains(where: { $0.status == .overage }) {
            return "Overstock"
        }
        return "Balanced"
    }

    private var statusTint: Color {
        switch statusSummary {
        case "Needs review":
            return .orange
        case "Overstock":
            return .blue
        case "Balanced":
            return .green
        default:
            return .white.opacity(0.65)
        }
    }

    private func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}

// MARK: - Rows

private struct LogItemSummary: Identifiable {
    public var id: String { itemName }
    public let summary: CalculationSummary
    public let entries: [ReceivingEntry]
    public let distributionGroup: FloorRangeGroup?

    public var itemName: String { summary.itemName }
}

private struct EntryRow: View {
    public let entry: ReceivingEntry

    public var body: some View {
        PremiumCard(accentColor: LinenIconLibrary.color(forItem: entry.itemName)) {
            HStack(spacing: 10) {
                LinenItemIcon(itemName: entry.itemName, size: 38, boxed: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.itemName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    if entry.countMethod == .fixedBin {
                        Text("\(entry.binCount ?? 0) bins × \(entry.piecesPerBin ?? 0) pcs")
                            .font(.caption).foregroundStyle(.white.opacity(0.6))
                    } else {
                        Text("Manual: \(entry.manualPieces ?? 0) pcs")
                            .font(.caption).foregroundStyle(.white.opacity(0.6))
                    }
                }
                Spacer()
                Text("\(entry.calculatedPieces) pcs · \(entry.calculatedFullBundles) bundles + \(entry.loosePieces)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
        }
    }
}

private struct ExpandableLogItemSummaryRow: View {
    public let itemSummary: LogItemSummary
    public let isExpanded: Bool
    public let onToggle: () -> Void

    private var summary: CalculationSummary { itemSummary.summary }

    public var body: some View {
        Button(action: onToggle) {
            PremiumCard(accentColor: LinenIconLibrary.color(forItem: summary.itemName)) {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    compactFacts

                    if isExpanded {
                        Divider().overlay(Color.white.opacity(0.08))
                        expandedDetails
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(spacing: 10) {
            LinenItemIcon(itemName: summary.itemName, size: 38, boxed: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.itemName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(primaryBundleLine)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            Spacer()
            StatusBadge(status: summary.status)
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    private var compactFacts: some View {
        HStack(spacing: 8) {
            fact("Received", "\(summary.fullBundles)", "bundles", emphasis: true)
            fact("Loose", "\(summary.loosePieces)", "pcs")
            fact(shortageOverageLabel, shortageOverageValue, shortageOverageUnit)
        }
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailGrid
            floorPlanSummary
            entrySummary
        }
    }

    private var detailGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                fact("Received", "\(summary.receivedPieces)", "pcs")
                fact("Required", "\(summary.requiredPieces)", "pcs")
                fact("Difference", signed(summary.differencePieces), "pcs")
            }

            HStack(spacing: 8) {
                fact("Delivered", "\(summary.deliverableBundles)", "bundles", emphasis: true)
                fact("Shortage", "\(summary.shortageBundles)", "bundles")
                fact("Leftover", "\(summary.leftoverBundles)", "bundles")
            }
        }
    }

    @ViewBuilder
    private var floorPlanSummary: some View {
        if let group = itemSummary.distributionGroup, !group.ranges.isEmpty {
            VStack(alignment: .leading, spacing: 7) {
                miniHeader("Floor plan", systemImage: "square.grid.3x3.fill")
                ForEach(group.ranges) { range in
                    HStack {
                        Text(range.label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))
                        Spacer()
                        Text(valueLabel(range.suggestedValue, unitIsBundles: group.unitIsBundles))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                        if range.isPlusOne {
                            Text("+1")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.22), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var entrySummary: some View {
        if !itemSummary.entries.isEmpty {
            VStack(alignment: .leading, spacing: 7) {
                miniHeader("Receiving", systemImage: "shippingbox.fill")
                ForEach(itemSummary.entries) { entry in
                    HStack(alignment: .top, spacing: 8) {
                        Text(receivingMethodText(entry))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                        Spacer()
                        Text("\(entry.calculatedPieces) pcs")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private var primaryBundleLine: String {
        "\(summary.fullBundles) full bundles · \(summary.loosePieces) loose pcs"
    }

    private var shortageOverageLabel: String {
        switch summary.status {
        case .shortage:
            return "Short"
        case .overage:
            return "Over"
        case .exact:
            return "Exact"
        }
    }

    private var shortageOverageValue: String {
        switch summary.status {
        case .shortage:
            return "\(summary.shortageBundles)"
        case .overage:
            return "\(summary.leftoverBundles)"
        case .exact:
            return "0"
        }
    }

    private var shortageOverageUnit: String {
        summary.status == .exact ? "gap" : "bundles"
    }

    private func fact(_ label: String, _ value: String, _ detail: String, emphasis: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(emphasis ? .blue : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.52))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }

    private func miniHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private func receivingMethodText(_ entry: ReceivingEntry) -> String {
        if entry.countMethod == .fixedBin {
            return "\(entry.binCount ?? 0) bins x \(entry.piecesPerBin ?? 0) pcs"
        }
        return "Manual \(entry.manualPieces ?? 0) pcs"
    }

    private func valueLabel(_ v: Int, unitIsBundles: Bool) -> String {
        if unitIsBundles {
            return v == 1 ? "1 bundle" : "\(v) bundles"
        }
        return "\(v) pcs"
    }

    private func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
