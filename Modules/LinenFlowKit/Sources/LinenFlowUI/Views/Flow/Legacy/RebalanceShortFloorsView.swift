import SwiftUI
import LinenFlowCore
import LinenFlowEngine

private enum FloorRebalanceInputMode: String, CaseIterable, Identifiable {
    case simple = "Simple"
    case advanced = "Advanced"

    public var id: String { rawValue }
}

private struct DraftRebalanceOverride: Identifiable, Equatable {
    public let id = UUID()
    public var startFloor: Int
    public var endFloor: Int
    public var pcsEach: Int
}

public struct RebalanceShortFloorsView: View {
    @Environment(FlowViewModel.self) private var viewModel

    public let preselectedItemName: String?

    @State private var selectedItemName = ""
    @State private var originalPCS = 0
    @State private var totalFloors = 1
    @State private var shortFloorStart = 1
    @State private var shortFloorEnd = 1
    @State private var pcsOnShortFloors = 0
    @State private var inputMode: FloorRebalanceInputMode = .simple
    @State private var manualOverrides: [DraftRebalanceOverride] = []
    @State private var result: FloorRebalanceResult?
    @State private var validationMessage: String?

    public init(preselectedItemName: String? = nil) {
        self.preselectedItemName = preselectedItemName
    }

    public var body: some View {
        AppBackground(accentColor: viewModel.selectedTower.flatMap { Color(hex: $0.identityColorHex ?? "") }) {
            ScrollView {
                VStack(spacing: 16) {
                    explanationCard
                    inputCard

                    if let validationMessage {
                        WarningCard(warnings: [validationMessage])
                    }

                    if let result {
                        pcsSummaryCard(result)
                        targetCard(result)
                        actionPlanCard(result)
                        recoveryStatusCard(result)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Rebalance Short Floors")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: configureInitialState)
        .onChange(of: selectedItemName) { _, _ in
            prefillForSelectedItem()
            result = nil
            validationMessage = nil
        }
    }

    private var explanationCard: some View {
        PremiumCard(accentColor: .orange) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.orange)
                        .frame(width: 34, height: 34)
                        .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I Ran Out / Rebalance")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Floor Rebalance Recovery Algorithm")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.56))
                    }
                    Spacer()
                }

                Text("Use this when you followed the floor plan but ran short because the count was wrong. Enter the short floor range and how many PCS those floors currently have. HimmerFlow will calculate what to collect back and where to deliver.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var inputCard: some View {
        PremiumCard(accentColor: viewModel.selectedTower.flatMap { Color(hex: $0.identityColorHex ?? "") }) {
            VStack(alignment: .leading, spacing: 12) {
                itemPicker
                modePicker

                PremiumInputPair(spacing: 10) {
                    PremiumNumberInput(label: "Original PCS", value: $originalPCS, suffix: "pcs", showArithmeticKeys: true)
                } trailing: {
                    PremiumNumberInput(label: "Total floors", value: $totalFloors, suffix: "floors", showArithmeticKeys: true)
                }

                switch inputMode {
                case .simple:
                    simpleOverrideFields
                case .advanced:
                    advancedOverrideFields
                }

                PrimaryActionButton(
                    title: "Rebalance Floors",
                    systemImage: "arrow.triangle.2.circlepath",
                    isEnabled: !selectedItemName.isEmpty
                ) {
                    rebalance()
                }
            }
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $inputMode) {
            ForEach(FloorRebalanceInputMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: inputMode) { _, newMode in
            result = nil
            validationMessage = nil
            if newMode == .advanced, manualOverrides.isEmpty {
                manualOverrides = [DraftRebalanceOverride(
                    startFloor: shortFloorStart,
                    endFloor: shortFloorEnd,
                    pcsEach: pcsOnShortFloors
                )]
            }
        }
    }

    private var simpleOverrideFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            PremiumInputPair(spacing: 10) {
                PremiumNumberInput(label: "Short start", value: $shortFloorStart, suffix: "floor", showArithmeticKeys: true)
            } trailing: {
                PremiumNumberInput(label: "Short end", value: $shortFloorEnd, suffix: "floor", showArithmeticKeys: true)
            }

            PremiumNumberInput(
                label: "PCS currently on short floors",
                value: $pcsOnShortFloors,
                suffix: "pcs each",
                showArithmeticKeys: true
            )
        }
    }

    private var advancedOverrideFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Manual wrong floor ranges")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.86))
                    Text("Use this when more than one floor range has the wrong current PCS.")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.50))
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    addManualOverride()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }

            ForEach($manualOverrides) { $override in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Range")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.58))
                        Spacer()
                        if manualOverrides.count > 1 {
                            Button {
                                removeManualOverride(override.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red.opacity(0.86))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    PremiumInputPair(spacing: 10) {
                        PremiumNumberInput(label: "Start", value: $override.startFloor, suffix: "floor", showArithmeticKeys: true)
                    } trailing: {
                        PremiumNumberInput(label: "End", value: $override.endFloor, suffix: "floor", showArithmeticKeys: true)
                    }
                    PremiumNumberInput(
                        label: "PCS currently on these floors",
                        value: $override.pcsEach,
                        suffix: "pcs each",
                        showArithmeticKeys: true
                    )
                }
                .padding(10)
                .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }

    private var itemPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Item")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))

            Menu {
                ForEach(availableItemNames, id: \.self) { itemName in
                    Button(itemName) {
                        selectedItemName = itemName
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    LinenItemIcon(itemName: selectedItemName, size: 28, boxed: true)
                    Text(selectedItemName.isEmpty ? "Select item" : selectedItemName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.48))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func pcsSummaryCard(_ result: FloorRebalanceResult) -> some View {
        resultCard(title: "PCS Summary", systemImage: "number", tint: .blue) {
            HStack(spacing: 10) {
                metric("Original PCS", "\(result.originalPCS)", tint: .white)
                metric("Actual PCS Found", "\(result.actualPCS)", tint: .green)
            }
            HStack(spacing: 10) {
                metric("Count Error", missingText(result.missingPCS), tint: result.missingPCS == 0 ? .white : .orange)
                metric("Floors", "\(result.totalFloors)", tint: .white)
            }
        }
    }

    private func targetCard(_ result: FloorRebalanceResult) -> some View {
        resultCard(title: "New Target", systemImage: "scope", tint: .green) {
            actionRows(result.groupedFinalTargets) { action in
                "\(floorLabel(action)): \(action.pcsEach) pcs each"
            }
        }
    }

    private func actionPlanCard(_ result: FloorRebalanceResult) -> some View {
        resultCard(title: "Action Plan", systemImage: "figure.walk.motion", tint: .orange) {
            actionSection(
                title: "Collect Back",
                emptyText: "No floors have extra pieces.",
                actions: result.groupedActions.filter { $0.actionType == .collectBack },
                tint: .orange
            )
            actionSection(
                title: "Deliver",
                emptyText: "No short floors need pieces.",
                actions: result.groupedActions.filter { $0.actionType == .deliver },
                tint: .green
            )
        }
    }

    private func recoveryStatusCard(_ result: FloorRebalanceResult) -> some View {
        resultCard(title: "Recovery Status", systemImage: result.isBalanced ? "checkmark.seal.fill" : "exclamationmark.triangle.fill", tint: result.isBalanced ? .green : .red) {
            HStack(spacing: 10) {
                metric("Collect back", "\(result.totalCollectBackPCS) pcs", tint: .orange)
                metric("Deliver", "\(result.totalDeliverPCS) pcs", tint: .green)
            }
            if let bundleSize = selectedBundleSize {
                Text("Bundle helper text uses \(bundleSize) pcs per bundle for display only. Recovery math stays in PCS.")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) {
                Image(systemName: result.isBalanced ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(result.isBalanced ? .green : .red)
                Text(result.isBalanced ? "Recovery balanced" : "Recovery is not balanced")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(10)
            .background((result.isBalanced ? Color.green : Color.red).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func resultCard<Content: View>(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        PremiumCard(accentColor: tint) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                content()
            }
        }
    }

    private func metric(_ label: String, _ value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func actionSection(title: String, emptyText: String, actions: [FloorRebalanceAction], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tint)
                .textCase(.uppercase)
            if actions.isEmpty {
                Text(emptyText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                actionRows(actions) { action in
                    "\(floorLabel(action)): \(actionText(action))"
                }
            }
        }
    }

    private func actionRows(_ actions: [FloorRebalanceAction], label: @escaping (FloorRebalanceAction) -> String) -> some View {
        VStack(spacing: 7) {
            ForEach(actions) { action in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label(action))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(2)
                        if let helper = bundleHelperText(for: action.pcsEach) {
                            Text(helper)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white.opacity(0.48))
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Text("\(action.totalPCS) pcs")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func configureInitialState() {
        if selectedItemName.isEmpty {
            selectedItemName = preselectedItemName ?? availableItemNames.first ?? ""
        }
        prefillForSelectedItem()
        if manualOverrides.isEmpty {
            manualOverrides = [DraftRebalanceOverride(startFloor: shortFloorStart, endFloor: shortFloorEnd, pcsEach: pcsOnShortFloors)]
        }
    }

    private func prefillForSelectedItem() {
        if let summary = viewModel.calculationSummaries.first(where: { $0.itemName == selectedItemName }) {
            originalPCS = summary.receivedPieces
        }
        if let tower = viewModel.selectedTower {
            totalFloors = tower.floorCount
            shortFloorStart = min(max(shortFloorStart, 1), tower.floorCount)
            shortFloorEnd = min(max(shortFloorEnd, shortFloorStart), tower.floorCount)
            manualOverrides = manualOverrides.map { override in
                DraftRebalanceOverride(
                    startFloor: min(max(override.startFloor, 1), tower.floorCount),
                    endFloor: min(max(override.endFloor, override.startFloor), tower.floorCount),
                    pcsEach: max(0, override.pcsEach)
                )
            }
        }
    }

    private func rebalance() {
        let request = FloorRebalanceRequest(
            itemName: selectedItemName,
            originalPCS: originalPCS,
            totalFloors: totalFloors,
            originalPlan: viewModel.floorDistributions,
            shortFloorStart: shortFloorStart,
            shortFloorEnd: shortFloorEnd,
            pcsOnShortFloors: pcsOnShortFloors,
            manualOverrideRanges: inputMode == .advanced ? manualOverrides.map {
                FloorRebalanceOverrideRange(
                    startFloor: $0.startFloor,
                    endFloor: $0.endFloor,
                    pcsEach: $0.pcsEach
                )
            } : []
        )

        do {
            result = try FloorRebalanceService().rebalanceShortFloors(request)
            validationMessage = nil
        } catch {
            result = nil
            validationMessage = (error as? LocalizedError)?.errorDescription ?? "Could not rebalance floors."
        }
    }

    private var availableItemNames: [String] {
        let summaryNames = viewModel.calculationSummaries.map(\.itemName)
        if !summaryNames.isEmpty {
            return summaryNames.sorted()
        }
        return viewModel.itemDisplayGroups(for: viewModel.selectedTower)
            .flatMap(\.items)
            .map(\.name)
            .sorted()
    }

    private var selectedBundleSize: Int? {
        viewModel.availableItems.first { $0.name == selectedItemName }?.bundleSize
            ?? viewModel.calculationSummaries.first { $0.itemName == selectedItemName }?.bundleSize
    }

    private func addManualOverride() {
        let start = manualOverrides.last?.endFloor ?? shortFloorEnd
        let nextStart = min(max(start + 1, 1), totalFloors)
        manualOverrides.append(DraftRebalanceOverride(
            startFloor: nextStart,
            endFloor: nextStart,
            pcsEach: 0
        ))
        result = nil
        validationMessage = nil
    }

    private func removeManualOverride(_ id: UUID) {
        manualOverrides.removeAll { $0.id == id }
        if manualOverrides.isEmpty {
            manualOverrides = [DraftRebalanceOverride(startFloor: shortFloorStart, endFloor: shortFloorEnd, pcsEach: pcsOnShortFloors)]
        }
        result = nil
        validationMessage = nil
    }

    private func floorLabel(_ action: FloorRebalanceAction) -> String {
        action.startFloor == action.endFloor ? "Floor \(action.startFloor)" : "Floors \(action.startFloor)-\(action.endFloor)"
    }

    private func actionText(_ action: FloorRebalanceAction) -> String {
        switch action.actionType {
        case .collectBack:
            return "collect \(action.pcsEach) pcs each"
        case .deliver:
            return "deliver \(action.pcsEach) pcs each"
        case .noChange:
            return "\(action.pcsEach) pcs each"
        }
    }

    private func bundleHelperText(for pieces: Int) -> String? {
        guard let bundleSize = selectedBundleSize, bundleSize > 0, pieces > 0 else { return nil }
        let fullBundles = pieces / bundleSize
        let loosePieces = pieces % bundleSize
        if fullBundles == 0 {
            return "\(loosePieces) loose pcs"
        }
        if loosePieces == 0 {
            return "\(fullBundles) full bdl"
        }
        return "\(fullBundles) full bdl + \(loosePieces) loose"
    }

    private func missingText(_ missingPCS: Int) -> String {
        if missingPCS > 0 { return "\(missingPCS) short" }
        if missingPCS < 0 { return "+\(abs(missingPCS)) extra" }
        return "0"
    }
}

/// Side-by-side premium inputs when width allows; stacks vertically when the operator strip would squeeze.
private struct PremiumInputPair<Leading: View, Trailing: View>: View {
    public var spacing: CGFloat = 10
    @ViewBuilder public var leading: () -> Leading
    @ViewBuilder public var trailing: () -> Trailing

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: spacing) {
                leading()
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailing()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: spacing) {
                leading()
                trailing()
            }
        }
    }
}
