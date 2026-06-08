import SwiftUI

enum LinenCardBackground: String, CaseIterable, Identifiable {
    case accent
    case trueBlack
    case subtle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .accent: return "Accent"
        case .trueBlack: return "True Black"
        case .subtle: return "Subtle"
        }
    }

    var systemImage: String {
        switch self {
        case .accent: return "paintpalette.fill"
        case .trueBlack: return "circle.fill"
        case .subtle: return "circle.lefthalf.filled"
        }
    }

    var cardStyle: PremiumCardStyle {
        switch self {
        case .accent: return .fullAccent
        case .trueBlack: return .solid(.black)
        case .subtle: return .standard
        }
    }
}

struct OneScreenLinenItemCard: View {
    let item: LinenItem
    let entry: ReceivingEntry?
    let summary: CalculationSummary?
    let distributionRows: [FloorDistributionRow]
    let unitIsBundles: Bool
    let onPiecesChange: (Int) -> Void
    var focusRequest: Int = 0
    var focusReleaseRequest: Int = 0
    var isCompactPinned: Bool = false
    var onEditRequested: (() -> Void)? = nil
    var onFocusChange: ((Bool) -> Void)? = nil

    @Environment(FlowViewModel.self) private var viewModel
    @State private var cardBackground: LinenCardBackground = .accent
    @State private var expression: String
    @State private var pieces: Int
    @State private var distributionExpanded = true
    @State private var floorOrderDescending = true

    private var cardBackgroundKey: String {
        "linen.card.background.\(item.id.uuidString)"
    }

    init(
        item: LinenItem,
        entry: ReceivingEntry?,
        summary: CalculationSummary?,
        distributionRows: [FloorDistributionRow],
        unitIsBundles: Bool,
        focusRequest: Int = 0,
        focusReleaseRequest: Int = 0,
        isCompactPinned: Bool = false,
        onEditRequested: (() -> Void)? = nil,
        onFocusChange: ((Bool) -> Void)? = nil,
        onPiecesChange: @escaping (Int) -> Void
    ) {
        self.item = item
        self.entry = entry
        self.summary = summary
        self.distributionRows = distributionRows
        self.unitIsBundles = unitIsBundles
        self.focusRequest = focusRequest
        self.focusReleaseRequest = focusReleaseRequest
        self.isCompactPinned = isCompactPinned
        self.onEditRequested = onEditRequested
        self.onFocusChange = onFocusChange
        self.onPiecesChange = onPiecesChange
        let initialPieces = entry?.calculatedPieces ?? 0
        _pieces = State(initialValue: initialPieces)
        _expression = State(initialValue: initialPieces > 0 ? "\(initialPieces)" : "")
    }

    var body: some View {
        PremiumCard(accentColor: accent, style: cardBackground.cardStyle) {
            VStack(alignment: .leading, spacing: 8) {
                if isCompactPinned {
                    compactPinnedHeader
                } else {
                    cardHeader
                }
                PremiumExpressionInput(
                    label: "",
                    expression: $expression,
                    evaluated: $pieces,
                    suffix: bundleConversionLabel,
                    focusRequest: focusRequest,
                    focusReleaseRequest: focusReleaseRequest,
                    showArithmeticKeys: isCompactPinned,
                    onFocusChange: onFocusChange
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onEditRequested?()
                }
                .onChange(of: pieces) { oldValue, newValue in
                    guard oldValue != newValue else { return }
                    onPiecesChange(newValue)
                }

                if isCompactPinned {
                    compactBundleStatRow
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if summary != nil {
                    resultSection()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.snappy(duration: 0.28), value: isCompactPinned)
        .contextMenu {
            Picker("Card Background", selection: $cardBackground) {
                ForEach(LinenCardBackground.allCases) { background in
                    Label(background.displayName, systemImage: background.systemImage)
                        .tag(background)
                }
            }
        }
        .onAppear {
            if let raw = UserDefaults.standard.string(forKey: cardBackgroundKey),
               let saved = LinenCardBackground(rawValue: raw) {
                cardBackground = saved
            }
        }
        .onChange(of: cardBackground) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: cardBackgroundKey)
        }
        .onChange(of: entry?.calculatedPieces ?? 0) { _, newValue in
            if newValue == 0 {
                expression = ""
                pieces = 0
            } else if pieces != newValue {
                expression = "\(newValue)"
                pieces = newValue
            }
        }
    }

    private var compactPinnedHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            LinenItemIcon(itemName: item.name, size: 34, boxed: true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(entrySubtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            Spacer(minLength: 8)
            anomalyIndicator
            if let summary {
                compactStatusIcon(for: summary.status)
            }
        }
    }

    @ViewBuilder
    private var compactBundleStatRow: some View {
        if pieces > 0 {
            let conversion = LinenCalculatorService.convertPiecesToBundles(
                pieces: pieces,
                bundleSize: item.bundleSize
            )
            PremiumCardAdaptiveGrid(spacing: 6) {
                compactPinnedStat(label: "Pieces", value: pieces, tint: .white)
                compactPinnedStat(label: "Bundles", value: conversion.fullBundles, tint: .green, emphasis: true)
                compactPinnedStat(label: "Loose", value: conversion.loosePieces, tint: .orange)
            }
        }
    }

    private func compactPinnedStat(label: String, value: Int, tint: Color, emphasis: Bool = false) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(
            emphasis ? tint.opacity(0.18) : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(emphasis ? tint.opacity(0.22) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var cardHeader: some View {
        ViewThatFits(in: .horizontal) {
            cardHeaderInline
            cardHeaderStacked
        }
    }

    private var cardHeaderInline: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                cardHeaderIdentity
                Spacer(minLength: 8)
                cardHeaderTrailingControls
            }

            cardHeaderMetaRow
        }
    }

    private var cardHeaderStacked: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                cardHeaderIdentity
                Spacer(minLength: 8)
                anomalyIndicator
                statusIcon
            }

            PremiumCardAdaptiveGrid(spacing: 6, columnCount: 2) {
                tripSelectionPill
                activeDeliveryPill
            }

            cardHeaderMetaRow
        }
    }

    private var cardHeaderIdentity: some View {
        HStack(alignment: .center, spacing: 10) {
            LinenItemIcon(itemName: item.name, size: 38, boxed: true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text(entrySubtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var cardHeaderTrailingControls: some View {
        anomalyIndicator
        tripSelectionPill
        activeDeliveryPill
        statusIcon
    }

    @ViewBuilder
    private var cardHeaderMetaRow: some View {
        HStack(spacing: 6) {
            if viewModel.usesParSystem {
                headerPill(unitIsBundles ? "Par \(item.parCount) bdl" : "Par \(item.parCount)", tint: .blue)
            } else {
                headerPill("No par cap", tint: .teal)
            }
            headerPill("×\(item.bundleSize)", tint: .green)
            Spacer(minLength: 6)
            if let summary {
                headerPill(summary.status.displayName, tint: statusTint(summary.status))
            }
        }
    }
    @ViewBuilder
    private var statusIcon: some View {
        if let summary {
            compactStatusIcon(for: summary.status)
        }
    }

    private var supplyAnomaly: SupplyAnomaly? {
        viewModel.supplyAnomalies.first { $0.itemName == item.name }
    }

    @ViewBuilder
    private var anomalyIndicator: some View {
        if let anomaly = supplyAnomaly {
            Image(systemName: anomaly.direction == .unusuallyLow ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.purple)
                .frame(width: 24, height: 24)
                .background(Color.purple.opacity(0.16), in: Circle())
                .overlay(Circle().stroke(Color.purple.opacity(0.22), lineWidth: 1))
                .accessibilityLabel(anomaly.message)
        }
    }

    private var tripSelectionPill: some View {
        let isOnTrip = viewModel.currentTripItemNames.contains(item.name)
        let isFull = viewModel.currentTripItemNames.count >= 2
        let isDisabled = summary == nil || (!isOnTrip && isFull)
        return Button {
            viewModel.toggleCurrentTripItem(item.name)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isOnTrip ? "checkmark.circle.fill" : "plus.circle")
                    .font(.caption2.weight(.bold))
                Text(isOnTrip ? "On Trip" : "Trip")
                    .font(.caption2.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(isOnTrip ? .mint : .white.opacity(isDisabled ? 0.32 : 0.62))
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(isOnTrip ? Color.mint.opacity(0.16) : Color.white.opacity(0.07), in: Capsule())
            .overlay(Capsule().stroke(isOnTrip ? Color.mint.opacity(0.32) : Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(isOnTrip ? "Remove \(item.name) from current trip" : "Add \(item.name) to current trip")
        .accessibilityHint(summary == nil ? "Enter received pieces first." : (isDisabled ? "Two items already selected for this trip." : ""))
    }

    private var activeDeliveryPill: some View {
        let isActive = viewModel.currentDeliveryItemName == item.name
        return Button {
            viewModel.selectCurrentDeliveryItem(isActive ? nil : item.name)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isActive ? "dot.radiowaves.left.and.right" : "iphone.gen3")
                    .font(.caption2.weight(.bold))
                Text(isActive ? "Delivering" : "Widget")
                    .font(.caption2.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(isActive ? .green : .white.opacity(0.62))
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(isActive ? Color.green.opacity(0.16) : Color.white.opacity(0.07), in: Capsule())
            .overlay(Capsule().stroke(isActive ? Color.green.opacity(0.24) : Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isActive ? "Current widget delivery item" : "Show this item in widget")
    }

    private func compactStatusIcon(for status: CalculationStatus) -> some View {
        let color: Color = {
            switch status {
            case .shortage: return .red
            case .overage:  return .green
            case .exact:    return .blue
            }
        }()
        let iconName: String = {
            switch status {
            case .shortage: return "exclamationmark.triangle.fill"
            case .overage:  return "checkmark.circle.fill"
            case .exact:    return "equal.circle.fill"
            }
        }()

        return Image(systemName: iconName)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .frame(width: 24, height: 24)
            .background(color.opacity(0.16), in: Circle())
            .overlay(Circle().stroke(color.opacity(0.22), lineWidth: 1))
    }

    private func headerPill(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold).monospacedDigit())
            .foregroundStyle(tint.opacity(0.92))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(tint.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.18), lineWidth: 1))
    }

    private var bundleConversionLabel: String {
        guard unitIsBundles else { return "pcs" }
        guard item.bundleSize > 0 else { return "bdl" }
        let bundles = max(0, pieces) / item.bundleSize
        return "\(bundles) bdl"
    }

    private func resultSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.blue)
                Text("Per floor")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 5) {
                    Text(floorOrderDescending ? "Top down" : "Bottom up")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                    Image(systemName: floorOrderDescending ? "arrow.down" : "arrow.up")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.13), in: Capsule())
            }
            .contentShape(Rectangle())
            .onTapGesture {
                toggleFloorOrder()
            }
            .contextMenu {
                Button(distributionExpanded ? "Collapse Per Floor" : "Expand Per Floor") {
                    distributionExpanded.toggle()
                }
            }

            if distributionExpanded {
                if unitIsBundles, let summary {
                    bundleDeliveryStats(summary)
                } else if let summary {
                    if viewModel.usesParSystem {
                        pieceDeliveryStats(summary)
                    } else {
                        timesharePieceDeliveryStats(summary)
                    }
                }
                let groups = FloorRangeBuilder.build(from: distributionRows, unitIsBundles: unitIsBundles)
                if let group = groups.first, !group.ranges.isEmpty {
                    ForEach(mergedDisplayRanges(from: group.ranges)) { range in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(range.isPlusOne ? Color.blue : Color.white.opacity(0.28))
                                .frame(width: 5, height: 5)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(range.label)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.78))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text(floorCountLabel(range.floorCount))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.42))
                            }
                            Spacer(minLength: 8)
                            if range.isPlusOne {
                                Text("+1")
                                    .font(.caption.weight(.bold).monospacedDigit())
                                    .foregroundStyle(.blue)
                            }
                            Text("\(range.floorCount)")
                                .font(.caption2.weight(.heavy).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.76))
                                .frame(minWidth: 20)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.07), in: Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.09), lineWidth: 1))
                            Text(deliveryLabel(range.suggestedValue))
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(.white)
                                .frame(minWidth: 54, alignment: .trailing)
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(
                            range.isPlusOne ? Color.blue.opacity(0.11) : Color.white.opacity(0.045),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(range.isPlusOne ? Color.blue.opacity(0.16) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleFloorOrder()
                        }
                    }
                } else {
                    Text(unitIsBundles ? "No full bundles." : "No pieces.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
    }

    private func toggleFloorOrder() {
        if distributionExpanded {
            floorOrderDescending.toggle()
        } else {
            distributionExpanded = true
        }
    }

    private func bundleDeliveryStats(_ summary: CalculationSummary) -> some View {
        PremiumCardAdaptiveGrid(spacing: 6) {
            compactBundleStat("Can", summary.deliverableBundles, tint: .green)
            compactBundleStat("Short", summary.shortageBundles, tint: .red)
            compactBundleStat("Left", summary.leftoverBundles, tint: .orange)
        }
        .padding(.bottom, 2)
    }

    private func pieceDeliveryStats(_ summary: CalculationSummary) -> some View {
        PremiumCardAdaptiveGrid(spacing: 6) {
            compactBundleStat("Received", summary.receivedPieces, tint: .green)
            compactBundleStat("Required", summary.requiredPieces, tint: .blue)
            compactBundleStat("Net", summary.differencePieces, tint: summary.differencePieces < 0 ? .red : .orange)
        }
        .padding(.bottom, 2)
    }

    private func timesharePieceDeliveryStats(_ summary: CalculationSummary) -> some View {
        PremiumCardAdaptiveGrid(spacing: 6) {
            compactBundleStat("Received", summary.receivedPieces, tint: .green)
            compactBundleStat("Floors", distributionRows.count, tint: .blue)
            compactBundleStat("Remainder", summary.remainderPieces, tint: summary.remainderPieces > 0 ? .orange : .white)
        }
        .padding(.bottom, 2)
    }

    private func compactBundleStat(_ label: String, _ value: Int, tint: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }

    private func deliveryLabel(_ value: Int) -> String {
        unitIsBundles ? "\(value) bdl" : "\(value) pcs"
    }

    private func floorCount(for range: FloorRange) -> Int {
        max(range.lastFloor - range.firstFloor + 1, 1)
    }

    private func floorCountLabel(_ count: Int) -> String {
        return count == 1 ? "1 floor" : "\(count) floors"
    }

    private func mergedDisplayRanges(from ranges: [FloorRange]) -> [MergedFloorDisplayRange] {
        let ordered = floorOrderDescending ? ranges.reversed() : ranges
        var merged: [MergedFloorDisplayRange] = []

        for range in ordered {
            let segment = floorSegmentLabel(for: range)
            if let index = merged.firstIndex(where: {
                $0.suggestedValue == range.suggestedValue && $0.isPlusOne == range.isPlusOne
            }) {
                merged[index].segments.append(segment)
                merged[index].floorCount += floorCount(for: range)
            } else {
                merged.append(MergedFloorDisplayRange(
                    suggestedValue: range.suggestedValue,
                    isPlusOne: range.isPlusOne,
                    segments: [segment],
                    floorCount: floorCount(for: range)
                ))
            }
        }

        return merged
    }

    private func floorSegmentLabel(for range: FloorRange) -> String {
        if range.firstFloor == range.lastFloor {
            return "\(range.firstFloor)"
        }
        return floorOrderDescending ? "\(range.lastFloor)-\(range.firstFloor)" : "\(range.firstFloor)-\(range.lastFloor)"
    }

    private var accent: Color {
        LinenIconLibrary.color(forItem: item.name)
    }

    private var entrySubtitle: String {
        guard let entry else { return "No pieces entered" }
        return "\(entry.calculatedPieces) pcs · \(entry.calculatedFullBundles) bdl + \(entry.loosePieces) loose"
    }

    private func statusTint(_ status: CalculationStatus) -> Color {
        switch status {
        case .shortage: return .red
        case .overage: return .green
        case .exact: return .blue
        }
    }
}

private struct MergedFloorDisplayRange: Identifiable {
    let suggestedValue: Int
    let isPlusOne: Bool
    var segments: [String]
    var floorCount: Int

    var id: String {
        "\(suggestedValue)-\(isPlusOne)-\(segments.joined(separator: ","))"
    }

    var label: String {
        let joined = segments.joined(separator: ", ")
        return segments.count == 1 && !joined.contains("-") ? "Floor \(joined)" : "Floors \(joined)"
    }
}
