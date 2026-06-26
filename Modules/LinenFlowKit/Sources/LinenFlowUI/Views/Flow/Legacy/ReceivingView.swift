import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct ReceivingView: View {
    @Environment(FlowViewModel.self) private var viewModel
    @Binding public var path: NavigationPath

    @State private var expandedReceivingItemID: UUID?
    @State private var freshExpansionItemID: UUID?
    @State private var focusRequest = 0
    @State private var focusReleaseRequest = 0

    public var body: some View {
        AppBackground(accentColor: viewModel.selectedTower.flatMap { Color(hex: $0.identityColorHex ?? "") }) {
            ScrollView {
                VStack(spacing: 16) {
                    FlowProgressHeader(current: .receive)

                    if let tower = viewModel.selectedTower {
                        towerHeader(tower)
                    }

                    receivingDashboard

                    SectionHeader(
                        title: "Receive linen",
                        subtitle: "Enter what physically arrived. Arithmetic like 245*2 works."
                    )

                    if !viewModel.validationWarnings.isEmpty {
                        WarningCard(warnings: viewModel.validationWarnings)
                    }

                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(viewModel.itemDisplayGroups(for: viewModel.selectedTower)) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                ReceivingItemGroupHeader(group: section.group, count: section.items.count)
                                ForEach(section.items, id: \.id) { item in
                                    receivingItemCard(for: item)
                                        .id(item.id)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            receivingBottomChrome
        }
        .navigationTitle("Receive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                receivingEditingKeyboardBar
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.randomizeReceivingEntriesForTesting()
                    expandedReceivingItemID = nil
                    freshExpansionItemID = nil
                } label: {
                    Image(systemName: "dice.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .disabled(viewModel.selectedTower == nil)
                .accessibilityLabel("Randomize testing counts")
            }

            ToolbarItem(placement: .topBarTrailing) {
                quickJumpMenu
            }
        }
    }

    @ViewBuilder
    private var receivingBottomChrome: some View {
        StickyBottomActionBar {
            PrimaryActionButton(
                title: "Review Received Pieces",
                systemImage: "checklist",
                isEnabled: !viewModel.receivingEntries.isEmpty
            ) {
                path.append(FlowStep.review)
            }
        }
    }

    private func receivingItemCard(for item: LinenItem) -> some View {
        let isExpanded = expandedReceivingItemID == item.id
        let isLockedElsewhere = expandedReceivingItemID != nil && !isExpanded
        return makeReceivingCard(for: item, isExpanded: isExpanded)
            .opacity(isLockedElsewhere ? 0.42 : 1)
            .allowsHitTesting(!isLockedElsewhere)
            .overlay {
                if isExpanded {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LinenIconLibrary.color(forItem: item.name).opacity(0.55), lineWidth: 2)
                }
            }
    }

    private func makeReceivingCard(for item: LinenItem, isExpanded: Bool) -> some View {
        ItemReceivingCard(
            item: item,
            entry: viewModel.receivingEntries.first(where: { $0.itemName == item.name }),
            usesParSystem: viewModel.usesParSystem,
            isExpanded: isExpanded,
            focusRequest: isExpanded ? focusRequest : 0,
            focusReleaseRequest: isExpanded ? focusReleaseRequest : 0,
            isCompactPinned: false,
            onToggle: { handleToggle(for: item) },
            onUpdate: { binCount, manualPieces, physicalBinCount, notes in
                viewModel.addOrUpdateReceivingEntry(
                    item: item,
                    binCount: binCount,
                    manualPieces: manualPieces,
                    physicalBinCount: physicalBinCount,
                    notes: notes
                )
            },
            onDone: { handleDone(for: item) },
            onFocusChange: { focused in
                handleReceivingFocusChange(item: item, focused: focused)
            }
        )
    }

    @ViewBuilder
    private var quickJumpMenu: some View {
        let enteredNames = Set(viewModel.receivingEntries.map(\.itemName))
        let allItems = viewModel.itemDisplayGroups(for: viewModel.selectedTower).flatMap(\.items)
        let remaining = allItems.filter { !enteredNames.contains($0.name) }

        Menu {
            if remaining.isEmpty {
                Text("All items entered")
            } else {
                ForEach(remaining, id: \.id) { item in
                    Button {
                        guard expandedReceivingItemID == nil else { return }
                        expandedReceivingItemID = item.id
                        freshExpansionItemID = entryHasValue(for: item) ? nil : item.id
                        focusRequest += 1
                    } label: {
                        Label(item.name, systemImage: LinenIconLibrary.symbolName(forItem: item.name))
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.down.forward.square")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .accessibilityLabel("Jump to item")
        .disabled(expandedReceivingItemID != nil)
        .opacity(expandedReceivingItemID == nil ? 1 : 0.45)
    }

    private func towerHeader(_ tower: Tower) -> some View {
        PremiumCard(accentColor: Color(hex: tower.identityColorHex ?? "")) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tower.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(tower.floorCount) floors")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                let summary = entriesSummary
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(summary.items) items")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(summary.pieces) pcs")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    private var entriesSummary: (items: Int, pieces: Int) {
        (viewModel.receivingEntries.count,
         viewModel.receivingEntries.reduce(0) { $0 + $1.calculatedPieces })
    }

    private var orderedItems: [LinenItem] {
        viewModel.itemDisplayGroups(for: viewModel.selectedTower).flatMap(\.items)
    }

    private func entryHasValue(for item: LinenItem) -> Bool {
        let entry = viewModel.receivingEntries.first(where: { $0.itemName == item.name })
        return (entry?.calculatedPieces ?? 0) > 0
    }

    private func handleReceivingFocusChange(item: LinenItem, focused: Bool) {
        guard focused else { return }
        if let lockedID = expandedReceivingItemID {
            if lockedID != item.id {
                focusRequest += 1
            }
            return
        }
        expandedReceivingItemID = item.id
        freshExpansionItemID = entryHasValue(for: item) ? nil : item.id
    }

    private func handleToggle(for item: LinenItem) {
        if let lockedID = expandedReceivingItemID {
            if lockedID != item.id { return }
            return
        }
        expandedReceivingItemID = item.id
        freshExpansionItemID = entryHasValue(for: item) ? nil : item.id
        focusRequest += 1
    }

    @ViewBuilder
    private var receivingEditingKeyboardBar: some View {
        if expandedReceivingItemID != nil {
            KeyboardEditingToolbar(
                itemName: orderedItems.first(where: { $0.id == expandedReceivingItemID })?.name,
                canMovePrevious: canMoveToAdjacentItem(offset: -1),
                canMoveNext: canMoveToAdjacentItem(offset: 1),
                onPrevious: { moveToAdjacentItem(offset: -1) },
                onNext: { moveToAdjacentItem(offset: 1) },
                onDone: { handleKeyboardDone() }
            )
        }
    }

    private func handleKeyboardDone() {
        guard let currentID = expandedReceivingItemID,
              let item = orderedItems.first(where: { $0.id == currentID }) else {
            endEditing()
            return
        }
        handleDone(for: item)
    }

    private func endEditing() {
        focusReleaseRequest += 1
        expandedReceivingItemID = nil
    }

    private func canMoveToAdjacentItem(offset: Int) -> Bool {
        guard let currentID = expandedReceivingItemID,
              let index = orderedItems.firstIndex(where: { $0.id == currentID }) else {
            return false
        }
        let nextIndex = index + offset
        return orderedItems.indices.contains(nextIndex)
    }

    private func moveToAdjacentItem(offset: Int) {
        guard let currentID = expandedReceivingItemID,
              let index = orderedItems.firstIndex(where: { $0.id == currentID }) else {
            return
        }
        let nextIndex = index + offset
        guard orderedItems.indices.contains(nextIndex) else { return }
        let nextItem = orderedItems[nextIndex]
        expandedReceivingItemID = nextItem.id
        freshExpansionItemID = entryHasValue(for: nextItem) ? nil : nextItem.id
        focusRequest += 1
    }

    private func handleDone(for item: LinenItem) {
        let wasFresh = (freshExpansionItemID == item.id)
        let nowFilled = entryHasValue(for: item)

        if wasFresh && nowFilled, let next = nextUnfilledItem(after: item) {
            KeyboardEditingHaptics.success()
            expandedReceivingItemID = next.id
            freshExpansionItemID = next.id
            focusRequest += 1
        } else {
            freshExpansionItemID = nil
            endEditing()
        }
    }

    private func nextUnfilledItem(after currentItem: LinenItem) -> LinenItem? {
        let items = orderedItems
        guard let idx = items.firstIndex(where: { $0.id == currentItem.id }) else { return nil }
        return items[(idx + 1)...].first { !entryHasValue(for: $0) }
    }

    private var receivingDashboard: some View {
        let stats = receivingStats
        return PremiumCard(accentColor: stats.statusTint.opacity(0.8)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: stats.statusIcon)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(stats.statusTint)
                        .frame(width: 42, height: 42)
                        .background(stats.statusTint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(stats.title)
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                        Text(stats.nextAction)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.62))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(stats.completionPercent)%")
                            .font(.title3.weight(.heavy).monospacedDigit())
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("entered")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.48))
                    }
                }

                ProgressView(value: Double(stats.enteredItems), total: Double(max(stats.availableItems, 1)))
                    .tint(stats.statusTint)

                PremiumCardAdaptiveGrid(spacing: 8) {
                    dashboardMetric("Items", stats.enteredItems, systemImage: "square.grid.2x2.fill", tint: .blue)
                    dashboardMetric("Bundles", stats.fullBundles, systemImage: "shippingbox.fill", tint: .green)
                    dashboardMetric("Loose", stats.loosePieces, systemImage: "circle.grid.2x2.fill", tint: stats.loosePieces > 0 ? .orange : .white)
                    dashboardMetric("Fixed bins", stats.fixedBinEntries, systemImage: "archivebox.fill", tint: .cyan)
                }
            }
        }
    }

    private func dashboardMetric(_ label: String, _ value: Int, systemImage: String, tint: Color) -> some View {
        VStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint.opacity(0.95))
            Text("\(value)")
                .font(.headline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.52))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        )
    }

    private var receivingStats: ReceivingDashboardStats {
        let towerItems = viewModel.itemDisplayGroups(for: viewModel.selectedTower).flatMap(\.items)
        let entries = viewModel.receivingEntries
        let enteredItemNames = Set(entries.map(\.itemName))
        let fixedBinItemNames = Set(towerItems.filter { $0.countMethod == .fixedBin }.map(\.name))
        let fixedBinEntries = entries.filter { fixedBinItemNames.contains($0.itemName) && $0.calculatedPieces > 0 }.count
        let fullBundles = entries.reduce(0) { $0 + $1.calculatedFullBundles }
        let loosePieces = entries.reduce(0) { $0 + $1.loosePieces }
        let enteredItems = towerItems.filter { enteredItemNames.contains($0.name) }.count
        let availableItems = towerItems.count

        let completionPercent = availableItems == 0 ? 0 : min(100, Int((Double(enteredItems) / Double(availableItems) * 100).rounded()))
        let hasWarnings = !viewModel.validationWarnings.isEmpty

        if viewModel.selectedTower == nil {
            return ReceivingDashboardStats(
                title: "Choose a tower",
                nextAction: "Select the tower before entering received linen.",
                statusIcon: "building.2.crop.circle",
                statusTint: .blue,
                enteredItems: 0,
                availableItems: max(availableItems, 1),
                fullBundles: fullBundles,
                loosePieces: loosePieces,
                fixedBinEntries: fixedBinEntries,
                completionPercent: 0
            )
        }

        if enteredItems == 0 {
            return ReceivingDashboardStats(
                title: "Ready for counts",
                nextAction: "Start with Bath Towel bins, then enter PCS for the remaining items.",
                statusIcon: "tray.and.arrow.down.fill",
                statusTint: .cyan,
                enteredItems: enteredItems,
                availableItems: max(availableItems, 1),
                fullBundles: fullBundles,
                loosePieces: loosePieces,
                fixedBinEntries: fixedBinEntries,
                completionPercent: completionPercent
            )
        }

        if hasWarnings {
            return ReceivingDashboardStats(
                title: "Review counts",
                nextAction: "Some entries may need a recount before delivery planning.",
                statusIcon: "exclamationmark.triangle.fill",
                statusTint: .orange,
                enteredItems: enteredItems,
                availableItems: max(availableItems, 1),
                fullBundles: fullBundles,
                loosePieces: loosePieces,
                fixedBinEntries: fixedBinEntries,
                completionPercent: completionPercent
            )
        }

        return ReceivingDashboardStats(
            title: "Receiving in progress",
            nextAction: enteredItems == availableItems ? "Review received pieces and confirm the tower plan." : "Continue entering PCS for the remaining linen items.",
            statusIcon: enteredItems == availableItems ? "checkmark.seal.fill" : "bolt.horizontal.circle.fill",
            statusTint: enteredItems == availableItems ? .green : .blue,
            enteredItems: enteredItems,
            availableItems: max(availableItems, 1),
            fullBundles: fullBundles,
            loosePieces: loosePieces,
            fixedBinEntries: fixedBinEntries,
            completionPercent: completionPercent
        )
    }

}

private struct ReceivingDashboardStats {
    public let title: String
    public let nextAction: String
    public let statusIcon: String
    public let statusTint: Color
    public let enteredItems: Int
    public let availableItems: Int
    public let fullBundles: Int
    public let loosePieces: Int
    public let fixedBinEntries: Int
    public let completionPercent: Int
}

// MARK: - Item card

private struct ReceivingItemGroupHeader: View {
    public let group: LinenItemDisplayGroup
    public let count: Int

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: group.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(group.displayName)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.86))
                Text(group.subtitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            Text("\(count)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var tint: Color {
        switch group {
        case .bath: return .cyan
        case .bedding: return .indigo
        case .specialty: return .orange
        }
    }
}

private struct ItemReceivingCard: View {
    public let item: LinenItem
    public let entry: ReceivingEntry?
    public let usesParSystem: Bool
    public let isExpanded: Bool
    public var focusRequest: Int = 0
    public var focusReleaseRequest: Int = 0
    public var isCompactPinned: Bool = false
    public let onToggle: () -> Void
    public let onUpdate: (_ binCount: Int?, _ manualPieces: Int?, _ physicalBinCount: Int?, _ notes: String?) -> Void
    public let onDone: () -> Void
    public var onFocusChange: ((Bool) -> Void)? = nil

    @State private var binCount: Int
    @State private var expression: String
    @State private var pieces: Int
    @State private var physicalBins: Int
    @State private var showPhysicalBins = false

    public init(
        item: LinenItem,
        entry: ReceivingEntry?,
        usesParSystem: Bool,
        isExpanded: Bool,
        focusRequest: Int = 0,
        focusReleaseRequest: Int = 0,
        isCompactPinned: Bool = false,
        onToggle: @escaping () -> Void,
        onUpdate: @escaping (_ binCount: Int?, _ manualPieces: Int?, _ physicalBinCount: Int?, _ notes: String?) -> Void,
        onDone: (() -> Void)? = nil,
        onFocusChange: ((Bool) -> Void)? = nil
    ) {
        self.item = item
        self.entry = entry
        self.usesParSystem = usesParSystem
        self.isExpanded = isExpanded
        self.focusRequest = focusRequest
        self.focusReleaseRequest = focusReleaseRequest
        self.isCompactPinned = isCompactPinned
        self.onToggle = onToggle
        self.onUpdate = onUpdate
        self.onDone = onDone ?? onToggle
        self.onFocusChange = onFocusChange
        _binCount = State(initialValue: entry?.binCount ?? 0)
        _pieces = State(initialValue: entry?.calculatedPieces ?? 0)
        _physicalBins = State(initialValue: entry?.physicalBinCount ?? 0)
        _showPhysicalBins = State(initialValue: (entry?.physicalBinCount ?? 0) > 0)
        let initialExpression: String = {
            if item.countMethod == .fixedBin { return "" }
            if let p = entry?.manualPieces, p > 0 { return String(p) }
            return ""
        }()
        _expression = State(initialValue: initialExpression)
    }

    public var body: some View {
        PremiumCard(accentColor: LinenIconLibrary.color(forItem: item.name)) {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: onToggle) {
                    VStack(alignment: .leading, spacing: 10) {
                        header
                        collapsedSummary
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(isExpanded ? "Double tap to collapse editor." : "Double tap to edit.")

                if isExpanded {
                    Divider().overlay(Color.white.opacity(0.08))
                    input
                    bundleStrip
                    if !isCompactPinned {
                        Button(action: onDone) {
                            Label("Done", systemImage: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.blue)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .animation(.snappy(duration: 0.28), value: isExpanded)
        .animation(.snappy(duration: 0.28), value: isCompactPinned)
    }

    private var header: some View {
        HStack(spacing: 10) {
            LinenItemIcon(itemName: item.name, size: 40, boxed: true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    if item.countMethod == .fixedBin {
                        Text("Fixed Bin")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.18), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                }

                Text(usesParSystem ? "Par \(item.parCount)/floor" : "Timeshare: no par cap")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    private var collapsedSummary: some View {
        let conversion = LinenCalculatorService.convertPiecesToBundles(
            pieces: pieces,
            bundleSize: item.bundleSize
        )

        return VStack(alignment: .leading, spacing: 3) {
            if item.countMethod == .fixedBin {
                if pieces > 0 {
                    Text("\(binCount) bins · \(pieces) pcs")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.9))
                    Text("\(conversion.fullBundles) bundles · \(conversion.loosePieces) loose")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.62))
                    if !isExpanded {
                        Text("Tap to edit")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                } else {
                    Text("Fixed Bin · \(item.piecesPerBin ?? 0) pcs/bin")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                    Text("Tap to enter bins")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            } else if pieces > 0 {
                Text("\(pieces) pcs received")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.9))
                Text("\(conversion.fullBundles) bundles · \(conversion.loosePieces) loose")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.62))
                if physicalBins > 0 {
                    Text("\(physicalBins) bins logged")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.cyan.opacity(0.82))
                }
                if !isExpanded {
                    Text("Tap to edit")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            } else {
                Text("Manual PCS · \(item.bundleSize) pcs/bundle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                Text("Tap to enter received pcs")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    @ViewBuilder
    private var input: some View {
        if item.countMethod == .fixedBin {
            let perBin = item.piecesPerBin ?? 0
            PremiumNumberInput(
                label: "Bins (× \(perBin) pcs each)",
                value: $binCount,
                suffix: "bins",
                requestsFocusOnAppear: true,
                focusRequest: focusRequest,
                focusReleaseRequest: focusReleaseRequest,
                showArithmeticKeys: true,
                onFocusChange: onFocusChange
            )
            .onChange(of: binCount) { _, new in
                pieces = new * perBin
                onUpdate(new, nil, nil, nil)
            }
        } else {
            PremiumExpressionInput(
                label: "Pieces received",
                expression: $expression,
                evaluated: $pieces,
                suffix: "pcs",
                requestsFocusOnAppear: true,
                focusRequest: focusRequest,
                focusReleaseRequest: focusReleaseRequest,
                showArithmeticKeys: true,
                onFocusChange: onFocusChange
            )
            .onChange(of: pieces) { _, new in
                onUpdate(nil, new, physicalBins > 0 ? physicalBins : nil, nil)
            }

            if !isCompactPinned {
                if showPhysicalBins {
                    PremiumNumberInput(
                        label: "Physical bins (optional)",
                        value: $physicalBins,
                        suffix: "bins",
                        showArithmeticKeys: true
                    )
                    .onChange(of: physicalBins) { _, new in
                        onUpdate(nil, pieces, new > 0 ? new : nil, nil)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else if pieces > 0 {
                    Button {
                        showPhysicalBins = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "archivebox")
                                .font(.caption2.weight(.bold))
                            Text("Add bin count")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var bundleStrip: some View {
        if pieces <= 0 {
            return AnyView(EmptyView())
        }
        let (full, loose) = LinenCalculatorService.convertPiecesToBundles(
            pieces: pieces, bundleSize: item.bundleSize
        )
        return AnyView(
            HStack(spacing: 10) {
                stat(label: "Pieces", value: "\(pieces)")
                stat(label: "Bundles", value: "\(full)", emphasis: true)
                stat(label: "Loose", value: "\(loose)")
                stat(label: "/bundle", value: "\(item.bundleSize)")
            }
        )
    }

    private func stat(label: String, value: String, emphasis: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(emphasis ? .white : .white.opacity(0.85))
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            emphasis ? Color.blue.opacity(0.18) : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    private var accessibilityLabel: String {
        if pieces <= 0 {
            return item.countMethod == .fixedBin
                ? "\(item.name), no bins entered."
                : "\(item.name), no pieces entered."
        }

        let conversion = LinenCalculatorService.convertPiecesToBundles(
            pieces: pieces,
            bundleSize: item.bundleSize
        )
        if item.countMethod == .fixedBin {
            return "\(item.name), \(binCount) bins, \(pieces) pieces, \(conversion.fullBundles) bundles."
        }
        return "\(item.name), \(pieces) pieces, \(conversion.fullBundles) bundles, \(conversion.loosePieces) loose pieces."
    }
}
