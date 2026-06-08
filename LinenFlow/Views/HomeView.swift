import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(FlowViewModel.self) private var viewModel
    @Environment(WidgetDeepLinkCoordinator.self) private var deepLinkCoordinator
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.createdAt, order: .reverse) private var logs: [DailyLog]
    @State private var savedConfirmation: String?
    @State private var hasAppeared = false
    @AppStorage("isCustomProperty") private var isCustomProperty = false
    @State private var towerPickerExpanded = false
    @State private var mapFocusTowerID: UUID?
    @State private var lastMapPreviewAt: Date = .distantPast
    @State private var itemPickerExpanded = false
    @State private var draftSelectedItemIDs: Set<UUID> = []
    @State private var showClearConfirmation = false
    @State private var focusedItemID: UUID?
    @State private var freshEditingItemID: UUID?
    @State private var focusRequest = 0
    @State private var focusReleaseRequest = 0
    @State private var showDeliveryCommandCenter = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            AppBackground(accentColor: selectedTowerColor) {
                ScrollView { flowContent }
                    .scrollDismissesKeyboard(.interactively)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        bottomChrome
                    }
            }
            .navigationTitle(viewModel.selectedTower?.name ?? "Linen Delivery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    itemEditingKeyboardBar
                }
            }
            .navigationDestination(isPresented: $showDeliveryCommandCenter) {
                ShiftCommandCenterView()
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: viewModel.selectedTower?.identityColorHex)
            .onAppear {
                viewModel.refreshAvailable()
                resetDraftSelectedItems()
                refreshShiftIntelligence()
                hasAppeared = true
            }
        }
        .onChange(of: viewModel.selectedTower?.id) { oldTowerID, newTowerID in
            resetDraftSelectedItems()
            itemPickerExpanded = false
            refreshShiftIntelligence()
            guard let newTowerID, oldTowerID == nil else { return }
            finishTowerPickerCollapse()
        }
        .onChange(of: logs.count) { _, _ in
            refreshShiftIntelligence()
        }
        .onChange(of: logs.first?.id) { _, _ in
            refreshShiftIntelligence()
        }
        .onChange(of: deepLinkCoordinator.openDeliveryCommandCenter) { _, shouldOpen in
            guard shouldOpen else { return }
            showDeliveryCommandCenter = true
            deepLinkCoordinator.consumeDeliveryCommandCenterRequest()
        }
    }

    private var flowContent: some View {
        VStack(spacing: 12) {
            header
            towerPicker

            if viewModel.selectedTower == nil {
                EmptyStateView(
                    systemImage: "building.2",
                    title: "Choose a tower",
                    message: "Select a tower to start."
                )
            } else {
                if viewModel.receivingEntries.isEmpty {
                    useLastLogCard
                    smartFillCard
                }
                itemSelectionCard
                if !viewModel.calculationSummaries.isEmpty {
                    summaryStrip
                }
                let actionableWarnings = viewModel.validationWarnings.filter {
                    !$0.hasPrefix("Select a tower") && !$0.hasPrefix("Enter at least one")
                }
                if !actionableWarnings.isEmpty {
                    WarningCard(warnings: actionableWarnings)
                }
                if !viewModel.receivingEntries.isEmpty {
                    notesField
                }
                inlineActions
                itemList
            }

            if let savedConfirmation {
                PremiumCard(accentColor: .green) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(savedConfirmation)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
            }

            Spacer(minLength: 28)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 12)
        .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: hasAppeared)
        .confirmationDialog("Clear received entries?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("Clear Entries", role: .destructive) {
                savedConfirmation = nil
                viewModel.clearEntries()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all entered supply for the current shift. This cannot be undone.")
        }
    }

    @ViewBuilder
    private var smartFillCard: some View {
        if viewModel.smartFillItemCount > 0, let summary = viewModel.smartFillSummary {
            SmartFillCard(
                summary: summary,
                itemCount: viewModel.smartFillItemCount,
                confidence: smartFillConfidence,
                onApply: applySmartFill
            )
        }
    }

    private var smartFillConfidence: PredictionConfidence? {
        let confidences = viewModel.supplyPredictions.filter(\.hasValue).map(\.confidence)
        guard !confidences.isEmpty else { return nil }
        if confidences.contains(.low) { return .low }
        if confidences.contains(.medium) { return .medium }
        return .high
    }

    private func refreshShiftIntelligence() {
        viewModel.updateShiftIntelligence(from: logs)
    }

    private func applySmartFill() {
        savedConfirmation = nil
        let applied = viewModel.applySmartFill()
        refreshShiftIntelligence()
        if applied > 0 {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            savedConfirmation = "Smart fill applied to \(applied) item\(applied == 1 ? "" : "s")."
        } else {
            savedConfirmation = "No smart fill values available."
        }
    }

    @ViewBuilder
    private var useLastLogCard: some View {
        if let log = latestLogForSelectedTower {
            PremiumCard(accentColor: .cyan) {
                PremiumCardActionRow {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.cyan.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Restore Last Log")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(lastLogSubtitle(log))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } trailing: {
                    Button {
                        savedConfirmation = nil
                        viewModel.loadFromLog(log)
                        resetDraftSelectedItems()
                        savedConfirmation = "Loaded last \(log.towerName) log."
                    } label: {
                        Label("Restore", systemImage: "arrow.down.doc.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Color.cyan.opacity(0.78), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Load last \(log.towerName) log")
                }
            }
        }
    }

    private var shiftCommanderStartButton: some View {
        let accent = selectedTowerColor ?? .blue
        let enabled = viewModel.selectedTower != nil
        return NavigationLink {
            ShiftCommandCenterView()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("Open Delivery")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [accent.opacity(0.95), accent.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: accent.opacity(0.35), radius: 10, y: 4)
            .opacity(enabled ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel("Open Delivery Command")
        .accessibilityHint(enabled ? "Opens countdown, pace, and completed floor tracking." : "Select a tower first.")
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background((selectedTowerColor ?? .blue).opacity(0.70), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.selectedTower?.name ?? "Linen Delivery")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(viewModel.selectedTower == nil ? "Select a tower to start" : "Today’s linen run")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                liveIndicator
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }

    private var statusAccentColor: Color {
        selectedTowerColor ?? .blue
    }

    private var activeDeliveryModeText: String {
        viewModel.deliveryUnitIsBundles ? "Bundle delivery" : "Piece distribution"
    }

    private var activeDeliveryModeIcon: String {
        viewModel.deliveryUnitIsBundles ? "shippingbox.fill" : "number"
    }

    private var activeDeliveryModeColor: Color {
        viewModel.deliveryUnitIsBundles ? statusAccentColor : .green
    }

    private var slimSummaryContent: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                slimSummaryStacked
            } else {
                ViewThatFits(in: .horizontal) {
                    slimSummaryInline
                    slimSummaryStacked
                }
            }
        }
    }

    private var slimSummaryInline: some View {
        HStack(spacing: 7) {
            slimSummaryLeading
            Spacer(minLength: 8)
            slimSummaryFactsInline
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke((selectedTowerColor ?? .white).opacity(0.12), lineWidth: 1)
        )
    }

    private var slimSummaryStacked: some View {
        VStack(alignment: .leading, spacing: 8) {
            slimSummaryLeading
            slimSummaryFactsGrid
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke((selectedTowerColor ?? .white).opacity(0.12), lineWidth: 1)
        )
    }

    private var slimSummaryLeading: some View {
        HStack(spacing: 7) {
            Image(systemName: activeDeliveryModeIcon)
                .font(.caption.weight(.bold))
                .foregroundStyle(activeDeliveryModeColor)
                .frame(width: 22, height: 22)
                .background(activeDeliveryModeColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(activeDeliveryModeText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
    }

    private var slimSummaryFactsInline: some View {
        HStack(spacing: 8) {
            compactInlineFact("\(totals.items)", "items", tint: .blue)
            compactInlineFact("\(totals.pieces)", "pcs", tint: .green)
            compactInlineFact("\(totals.bundles)", "bdl", tint: .indigo)
            if totals.loose > 0 {
                compactInlineFact("\(totals.loose)", "loose", tint: .orange)
            }
        }
    }

    private var slimSummaryFactsGrid: some View {
        PremiumCardAdaptiveGrid(spacing: 6, columnCount: 2) {
            compactInlineFact("\(totals.items)", "items", tint: .blue)
            compactInlineFact("\(totals.pieces)", "pcs", tint: .green)
            compactInlineFact("\(totals.bundles)", "bdl", tint: .indigo)
            if totals.loose > 0 {
                compactInlineFact("\(totals.loose)", "loose", tint: .orange)
            }
        }
    }

    private func compactInlineFact(_ value: String, _ label: String, tint: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint.opacity(0.9))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }

    private var liveIndicator: some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 10, height: 10)
                Circle()
                    .fill(Color.green)
                    .frame(width: 5, height: 5)
            }
            Text("Live")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(.green)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.green.opacity(0.11), in: Capsule())
    }

    private var selectedTowerColor: Color? {
        viewModel.selectedTower.flatMap { Color(hex: $0.identityColorHex ?? "") }
    }

    private var latestLogForSelectedTower: DailyLog? {
        guard let towerName = viewModel.selectedTower?.name else { return nil }
        return logs.first { $0.towerName == towerName }
    }

    private func lastLogSubtitle(_ log: DailyLog) -> String {
        let itemCount = log.entriesSnapshot.count
        let pieces = log.summarySnapshot.reduce(0) { $0 + $1.receivedPieces }
        let date = log.createdAt.formatted(date: .abbreviated, time: .shortened)
        return "\(itemCount) items · \(pieces) pcs · \(date)"
    }


    private func previewTowerOnMap(_ tower: Tower) {
        guard mapFocusTowerID != tower.id else { return }
        let now = Date.now
        guard now.timeIntervalSince(lastMapPreviewAt) >= 0.1 else { return }
        lastMapPreviewAt = now
        mapFocusTowerID = tower.id
    }

    private func selectTowerFromMap(_ tower: Tower) {
        savedConfirmation = nil
        mapFocusTowerID = tower.id
        viewModel.selectTower(tower)
    }

    private func finishTowerPickerCollapse() {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.28)) {
            towerPickerExpanded = false
            mapFocusTowerID = nil
        }
    }

    private var showsTowerEnvironmentMap: Bool {
        !isCustomProperty && (towerPickerExpanded || viewModel.selectedTower == nil)
    }

    private var towerPicker: some View {
        Group {
            if let tower = viewModel.selectedTower, !towerPickerExpanded {
                collapsedTowerPicker(tower)
            } else {
                expandedTowerPicker
            }
        }
    }

    private func collapsedTowerPicker(_ tower: Tower) -> some View {
        let color = Color(hex: tower.identityColorHex ?? "") ?? .blue

        return PremiumCard(accentColor: color) {
            PremiumCardActionRow {
                HStack(spacing: 10) {
                    Image("tower_\(tower.name.lowercased())")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                    compactActiveFloorControl(tower)
                }
            } trailing: {
                Button {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.28)) {
                        towerPickerExpanded = true
                        mapFocusTowerID = nil
                    }
                } label: {
                    Label("Change", systemImage: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(color.opacity(0.75), in: Capsule())
                }
                .accessibilityLabel("Change tower")
                .accessibilityHint("Opens the tower picker.")
            }
        }
    }

    private var expandedTowerPicker: some View {
        PremiumCard(accentColor: selectedTowerColor) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tower")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    if viewModel.selectedTower != nil && towerPickerExpanded {
                        Button("Done") {
                            finishTowerPickerCollapse()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .accessibilityLabel("Done selecting tower")
                        .accessibilityHint("Collapses the tower picker.")
                    }
                }

                if showsTowerEnvironmentMap {
                    towerEnvironmentSection
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.towerDisplayGroups) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            towerGroupHeader(section.group, count: section.towers.count)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 6)], spacing: 6) {
                                ForEach(section.towers, id: \.id) { tower in
                                    Button {
                                        selectTowerFromMap(tower)
                                    } label: {
                                        towerButtonLabel(tower, isPreviewing: mapFocusTowerID == tower.id)
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in previewTowerOnMap(tower) }
                                    )
                                }
                            }
                        }
                    }
                }

                if let tower = viewModel.selectedTower {
                    activeFloorControl(tower)
                }
            }
            .animation(reduceMotion ? nil : .snappy(duration: 0.28), value: showsTowerEnvironmentMap)
        }
    }

    private var towerEnvironmentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            TowerPickerEnvironmentView(
                towers: viewModel.availableTowers,
                selectedTower: viewModel.selectedTower,
                focusTowerID: mapFocusTowerID,
                isExpanded: true,
                hint: mapFocusTowerID == nil ? "Drag a tower to preview" : "Previewing tower location"
            )
        }
    }

    private func towerButtonLabel(_ tower: Tower, isPreviewing: Bool = false) -> some View {
        let isSelected = tower.id == viewModel.selectedTower?.id || isPreviewing
        let color = Color(hex: tower.identityColorHex ?? "") ?? .blue
        let iconName = "tower_\(tower.name.lowercased())"
        return VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                        .background(Circle().fill(Color.black.opacity(0.6)).padding(-2))
                        .offset(x: 4, y: -4)
                }
            }
            Text(tower.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            isSelected ? color.opacity(0.32) : Color.white.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? color.opacity(0.65) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .foregroundStyle(.white)
        .opacity(isSelected ? 1 : 0.78)
        .shadow(color: isSelected ? color.opacity(0.22) : .clear, radius: 8, y: 3)
    }

    private func compactActiveFloorControl(_ tower: Tower) -> some View {
        HStack(spacing: 6) {
            Text("Floors")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
            if let protectedFloorCount = TowerOperationalPolicy.confirmedDeliveryFloorCount(for: tower) {
                Label("\(protectedFloorCount)", systemImage: "lock.fill")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .labelStyle(.titleAndIcon)
            } else {
                Stepper(value: floorCountBinding(for: tower), in: 1...80) {
                    Text("\(tower.floorCount)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 24, alignment: .trailing)
                }
                .tint(.orange)
            }
        }
    }

    private func activeFloorControl(_ tower: Tower) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "hammer.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
            Text("Active floors")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
            Spacer()
            if let protectedFloorCount = TowerOperationalPolicy.confirmedDeliveryFloorCount(for: tower) {
                Label("\(protectedFloorCount)", systemImage: "lock.fill")
                    .font(.headline.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .labelStyle(.titleAndIcon)
                    .frame(minWidth: 48, alignment: .trailing)
            } else {
                Stepper(value: floorCountBinding(for: tower), in: 1...80) {
                    Text("\(tower.floorCount)")
                        .font(.headline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 28, alignment: .trailing)
                }
                .tint(.orange)
            }
        }
        .padding(.top, 4)
    }

    private func floorCountBinding(for tower: Tower) -> Binding<Int> {
        Binding(
            get: { tower.floorCount },
            set: { newValue in
                savedConfirmation = nil
                viewModel.updateSelectedTowerFloorCount(newValue)
            }
        )
    }

    @ViewBuilder
    private var itemSelectionCard: some View {
        if let tower = viewModel.selectedTower {
            PremiumCard(accentColor: selectedTowerColor) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "checklist")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background((selectedTowerColor ?? .blue).opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tower Items")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("\(draftSelectedItemIDs.count) of \(viewModel.availableItems.count) active for \(tower.name)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                        }

                        Spacer()

                        Button {
                            withAnimation(reduceMotion ? nil : .snappy(duration: 0.24)) {
                                itemPickerExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: itemPickerExpanded ? "chevron.up" : "slider.horizontal.3")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    if itemPickerExpanded {
                        HStack(spacing: 8) {
                            Button("All") {
                                draftSelectedItemIDs = Set(viewModel.availableItems.map(\.id))
                                savedConfirmation = nil
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.07), in: Capsule())

                            Button("Clear") {
                                draftSelectedItemIDs = []
                                savedConfirmation = nil
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.07), in: Capsule())

                            Spacer()

                            Button {
                                saveSelectedTowerItems()
                            } label: {
                                Label("Save Items", systemImage: "tray.and.arrow.down.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 7)
                                    .background(Color.blue.opacity(0.82), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8)], spacing: 8) {
                            ForEach(viewModel.itemDisplayGroups(for: nil)) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    itemGroupHeader(section.group, count: section.items.count)
                                    ForEach(section.items, id: \.id) { item in
                                        itemSelectionButton(item)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func itemSelectionButton(_ item: LinenItem) -> some View {
        let isSelected = draftSelectedItemIDs.contains(item.id)
        return Button {
            savedConfirmation = nil
            if isSelected {
                draftSelectedItemIDs.remove(item.id)
            } else {
                draftSelectedItemIDs.insert(item.id)
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .green : .white.opacity(0.38))
                LinenItemIcon(itemName: item.name, size: 26)
                Text(item.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.green.opacity(0.14) : Color.white.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.green.opacity(0.22) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var summaryStrip: some View {
        slimSummaryContent
    }

    private var notesField: some View {
        @Bindable var vm = viewModel
        return PremiumCard {
            HStack(spacing: 10) {
                Image(systemName: "note.text")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(width: 22)
                TextField("Add a note for this log", text: $vm.notes)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .tint(.blue)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }
        }
    }

    private var inlineActions: some View {
        HStack(spacing: 10) {
            Button {
                showClearConfirmation = true
            } label: {
                Label("Clear", systemImage: "xmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.78))
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button {
                saveLog()
            } label: {
                Label("Save Log", systemImage: "tray.and.arrow.down.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                viewModel.receivingEntries.isEmpty ? Color.white.opacity(0.08) : Color.blue.opacity(0.82),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .disabled(viewModel.receivingEntries.isEmpty)
            .opacity(viewModel.receivingEntries.isEmpty ? 0.65 : 1)
        }
    }

    private var itemList: some View {
        let columns = [GridItem(.flexible(), spacing: 10, alignment: .top)]
        return LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.itemDisplayGroups(for: viewModel.selectedTower)) { section in
                VStack(alignment: .leading, spacing: 8) {
                    itemGroupHeader(section.group, count: section.items.count)
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(section.items, id: \.id) { item in
                            itemCard(for: item)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var bottomChrome: some View {
        shiftCommanderStartButton
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
    }

    private func itemCard(for item: LinenItem) -> some View {
        let isFocused = focusedItemID == item.id
        let isLockedElsewhere = focusedItemID != nil && !isFocused
        return EquatableLinenListCard(
            item: item,
            entry: viewModel.receivingEntries.last { $0.itemName == item.name },
            summary: viewModel.calculationSummaries.first { $0.itemName == item.name },
            distributionRows: viewModel.deliveryFloorDistributions.filter { $0.itemName == item.name },
            unitIsBundles: viewModel.deliveryUnitIsBundles,
            hasSupplyAnomaly: viewModel.supplyAnomalies.contains { $0.itemName == item.name },
            isFocused: isFocused,
            focusRequest: isFocused ? focusRequest : 0,
            focusReleaseRequest: isFocused ? focusReleaseRequest : 0,
            onEditRequested: { activateEditing(item) },
            onFocusChange: { focused in
                handleItemFocusChange(item: item, focused: focused)
            }
        )
        .id(item.id)
        .opacity(isLockedElsewhere ? 0.42 : 1)
        .allowsHitTesting(!isLockedElsewhere)
        .accessibilityLabel(linenCardAccessibilityLabel(item: item, isFocused: isFocused, isLockedElsewhere: isLockedElsewhere))
        .accessibilityAddTraits(isFocused ? .isSelected : [])
    }

    private func linenCardAccessibilityLabel(item: LinenItem, isFocused: Bool, isLockedElsewhere: Bool) -> String {
        if isFocused {
            return "\(item.name), current editing item"
        }
        if isLockedElsewhere {
            return "\(item.name), locked while another item is being edited"
        }
        return item.name
    }

    private var itemsForSelectedTower: [LinenItem] {
        guard let tower = viewModel.selectedTower else { return [] }
        return viewModel.availableItems.filter { viewModel.itemIsAvailable($0, for: tower) }
    }

    private var orderedEditableItems: [LinenItem] {
        viewModel.itemDisplayGroups(for: viewModel.selectedTower).flatMap(\.items)
    }

    private var focusedItem: LinenItem? {
        guard let focusedItemID else { return nil }
        return orderedEditableItems.first { $0.id == focusedItemID }
    }

    @ViewBuilder
    private var itemEditingKeyboardBar: some View {
        if focusedItemID != nil {
            KeyboardEditingToolbar(
                itemName: focusedItem?.name,
                canMovePrevious: canMoveToAdjacentItem(offset: -1),
                canMoveNext: canMoveToAdjacentItem(offset: 1),
                onPrevious: { moveToAdjacentItem(offset: -1) },
                onNext: { moveToAdjacentItem(offset: 1) },
                onDone: { handleEditingDone() }
            )
        }
    }

    private func entryHasValue(for item: LinenItem) -> Bool {
        let entry = viewModel.receivingEntries.last { $0.itemName == item.name }
        return (entry?.calculatedPieces ?? 0) > 0
    }

    private func nextUnfilledItem(after currentItem: LinenItem) -> LinenItem? {
        let items = orderedEditableItems
        guard let idx = items.firstIndex(where: { $0.id == currentItem.id }) else { return nil }
        return items[(idx + 1)...].first { !entryHasValue(for: $0) }
    }

    private func handleEditingDone() {
        guard let focusedItem else {
            endEditing()
            return
        }

        let wasFresh = freshEditingItemID == focusedItem.id
        let nowFilled = entryHasValue(for: focusedItem)

        if wasFresh && nowFilled, let next = nextUnfilledItem(after: focusedItem) {
            KeyboardEditingHaptics.success()
            focusedItemID = next.id
            freshEditingItemID = next.id
            focusRequest += 1
        } else {
            endEditing()
            freshEditingItemID = nil
        }
    }

    private func activateEditing(_ item: LinenItem) {
        if let lockedID = focusedItemID, lockedID != item.id {
            focusRequest += 1
            return
        }
        if focusedItemID == item.id {
            focusRequest += 1
            return
        }
        focusedItemID = item.id
        freshEditingItemID = entryHasValue(for: item) ? nil : item.id
        focusRequest += 1
    }

    private func handleItemFocusChange(item: LinenItem, focused: Bool) {
        guard focused else { return }
        if let lockedID = focusedItemID {
            if lockedID != item.id {
                focusRequest += 1
            }
            return
        }
        activateEditing(item)
    }

    private func endEditing() {
        focusReleaseRequest += 1
        focusedItemID = nil
        freshEditingItemID = nil
    }

    private func canMoveToAdjacentItem(offset: Int) -> Bool {
        guard let currentID = focusedItemID,
              let index = orderedEditableItems.firstIndex(where: { $0.id == currentID }) else {
            return false
        }
        let nextIndex = index + offset
        return orderedEditableItems.indices.contains(nextIndex)
    }

    private func moveToAdjacentItem(offset: Int) {
        guard let currentID = focusedItemID,
              let index = orderedEditableItems.firstIndex(where: { $0.id == currentID }) else {
            return
        }
        let nextIndex = index + offset
        guard orderedEditableItems.indices.contains(nextIndex) else { return }
        let nextItem = orderedEditableItems[nextIndex]
        focusedItemID = nextItem.id
        freshEditingItemID = entryHasValue(for: nextItem) ? nil : nextItem.id
        focusRequest += 1
    }

    private func towerGroupHeader(_ group: TowerDisplayGroup, count: Int) -> some View {
        displayGroupHeader(
            title: group.displayName,
            subtitle: group.subtitle,
            count: count,
            systemImage: group.systemImage,
            tint: towerGroupColor(group)
        )
    }

    private func itemGroupHeader(_ group: LinenItemDisplayGroup, count: Int) -> some View {
        displayGroupHeader(
            title: group.displayName,
            subtitle: group.subtitle,
            count: count,
            systemImage: group.systemImage,
            tint: itemGroupColor(group)
        )
    }

    private func displayGroupHeader(title: String, subtitle: String, count: Int, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.86))
                Text(subtitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
            Text("\(count)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.top, 2)
    }

    private func towerGroupColor(_ group: TowerDisplayGroup) -> Color {
        switch group {
        case .pieceDistribution: return .green
        case .bundleDelivery: return selectedTowerColor ?? .blue
        }
    }

    private func itemGroupColor(_ group: LinenItemDisplayGroup) -> Color {
        switch group {
        case .bath: return .cyan
        case .bedding: return .indigo
        case .specialty: return .orange
        }
    }

    private func resetDraftSelectedItems() {
        guard let tower = viewModel.selectedTower else {
            draftSelectedItemIDs = []
            return
        }
        draftSelectedItemIDs = viewModel.selectedItemIDs(for: tower)
    }

    private func saveSelectedTowerItems() {
        guard let tower = viewModel.selectedTower else { return }
        do {
            try viewModel.saveSelectedItems(draftSelectedItemIDs, for: tower)
            resetDraftSelectedItems()
            savedConfirmation = "Tower items saved."
        } catch {
            savedConfirmation = "Could not save tower items."
        }
    }

    private var totals: (items: Int, pieces: Int, bundles: Int, loose: Int) {
        (
            viewModel.calculationSummaries.count,
            viewModel.calculationSummaries.reduce(0) { $0 + $1.receivedPieces },
            viewModel.calculationSummaries.reduce(0) { $0 + $1.fullBundles },
            viewModel.calculationSummaries.reduce(0) { $0 + $1.loosePieces }
        )
    }

    private func saveLog() {
        switch DailyLogSaveService.save(viewModel: viewModel, context: modelContext) {
        case .success:
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            savedConfirmation = "Daily log saved."
        case .failure(let err):
            savedConfirmation = err.errorDescription ?? "Save failed."
        }
    }
}

private struct EquatableLinenListCard: View, Equatable {
    @Environment(FlowViewModel.self) private var viewModel

    let item: LinenItem
    let entry: ReceivingEntry?
    let summary: CalculationSummary?
    let distributionRows: [FloorDistributionRow]
    let unitIsBundles: Bool
    let hasSupplyAnomaly: Bool
    let isFocused: Bool
    let focusRequest: Int
    let focusReleaseRequest: Int
    let onEditRequested: () -> Void
    let onFocusChange: (Bool) -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.item.id == rhs.item.id
            && lhs.entry?.calculatedPieces == rhs.entry?.calculatedPieces
            && lhs.summary?.receivedPieces == rhs.summary?.receivedPieces
            && lhs.summary?.status == rhs.summary?.status
            && lhs.distributionRows.count == rhs.distributionRows.count
            && lhs.unitIsBundles == rhs.unitIsBundles
            && lhs.hasSupplyAnomaly == rhs.hasSupplyAnomaly
            && lhs.isFocused == rhs.isFocused
            && (!lhs.isFocused || lhs.focusRequest == rhs.focusRequest)
            && (!lhs.isFocused || lhs.focusReleaseRequest == rhs.focusReleaseRequest)
    }

    var body: some View {
        OneScreenLinenItemCard(
            item: item,
            entry: entry,
            summary: summary,
            distributionRows: distributionRows,
            unitIsBundles: unitIsBundles,
            focusRequest: focusRequest,
            focusReleaseRequest: focusReleaseRequest,
            isCompactPinned: false,
            isFocused: isFocused,
            onEditRequested: onEditRequested,
            onFocusChange: onFocusChange
        ) { pieces in
            viewModel.addOrUpdateReceivedPieces(item: item, pieces: pieces)
        }
    }
}

