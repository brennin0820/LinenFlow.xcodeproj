import SwiftUI
import SwiftData

struct FloorDistributionView: View {
    @Environment(FlowViewModel.self) private var viewModel
    @Environment(ShiftSettings.self) private var shiftSettings
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath

    @State private var savedConfirmation: String?
    @State private var showChecklistClearConfirmation = false
    @State private var expandedFloorPlanItemName: String?
    @State private var isCurrentTripExpanded = false
    @State private var showAllFloorPlanItems = false

    var body: some View {
        AppBackground(accentColor: viewModel.selectedTower.flatMap { Color(hex: $0.identityColorHex ?? "") }) {
            ScrollView {
                VStack(spacing: 16) {
                    FlowProgressHeader(current: .floorPlan)

                    if let tower = viewModel.selectedTower {
                        headerCard(tower)
                    }

                    PremiumCard {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill").foregroundStyle(.blue)
                            Text(instructionText)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Spacer()
                        }
                    }

                    if let confirmation = savedConfirmation {
                        PremiumCard(accentColor: .green) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                Text(confirmation).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                Spacer()
                            }
                        }
                    }

                    if rangesByItem.isEmpty {
                        EmptyStateView(
                            systemImage: "building.columns",
                            title: "No distribution yet",
                            message: "Receive items and calculate results first."
                        )
                    } else {
                        deliverySessionHeaderCard
                        nextFloorLoadCard
                        deliveryChecklistCard
                        rebalanceEntryCard

                        floorPlanSection
                    }

                    loosePiecesFooter

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
        }
        .safeAreaInset(edge: .bottom) {
            StickyBottomActionBar {
                PrimaryActionButton(title: "Save Daily Log", systemImage: "tray.and.arrow.down.fill") {
                    saveLog()
                }
            }
        }
        .navigationTitle("Floor Plan")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Clear completed floors?", isPresented: $showChecklistClearConfirmation, titleVisibility: .visible) {
            Button("Clear Completed Floors", role: .destructive) {
                for floor in deliveryFloorNumbers {
                    viewModel.unmarkFloorComplete(floor)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This only clears the in-progress delivery checklist. It does not delete saved logs or change the floor plan.")
        }
    }

    private func headerCard(_ tower: Tower) -> some View {
        PremiumCard(accentColor: Color(hex: tower.identityColorHex ?? "")) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tower.name).font(.headline).foregroundStyle(.white)
                    Text("\(tower.floorCount) floors · \(rangesByItem.count) items")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var floorPlanSection: some View {
        let tripGroups = viewModel.currentTripRangesByItem
        let hasTrip = !viewModel.currentTripItemNames.isEmpty

        if hasTrip && !tripGroups.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.mint)
                    Text("Showing current trip items only")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                    Spacer()
                    Button {
                        showAllFloorPlanItems.toggle()
                    } label: {
                        Text(showAllFloorPlanItems ? "Trip Only" : "All Items")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.mint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.mint.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)

                let displayGroups = showAllFloorPlanItems ? rangesByItem : tripGroups
                ForEach(displayGroups, id: \.itemName) { group in
                    floorPlanCard(group)
                }
            }
        } else {
            ForEach(rangesByItem, id: \.itemName) { group in
                floorPlanCard(group)
            }
        }
    }

    private func floorPlanCard(_ group: FloorRangeGroup) -> some View {
        FloorPlanCard(
            group: group,
            summary: summary(for: group.itemName),
            item: item(for: group.itemName),
            isExpanded: expandedFloorPlanItemName == group.itemName,
            onToggle: {
                expandedFloorPlanItemName = expandedFloorPlanItemName == group.itemName ? nil : group.itemName
            }
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var rangesByItem: [FloorRangeGroup] {
        FloorRangeBuilder.build(
            from: viewModel.deliveryFloorDistributions,
            unitIsBundles: viewModel.deliveryUnitIsBundles
        )
    }

    private var deliveryFloorNumbers: [Int] {
        if !viewModel.deliverySessionState.deliveryFloors.isEmpty {
            return viewModel.deliverySessionState.deliveryFloors
        }
        let serviceFloors = DeliveryFloorSequenceService.deliveryFloors(for: viewModel.selectedTower)
        if !serviceFloors.isEmpty {
            return serviceFloors
        }
        return Array(Set(viewModel.deliveryFloorDistributions.map(\.floorNumber))).sorted()
    }

    private var checklistFloorSignature: String {
        deliveryFloorNumbers.map(String.init).joined(separator: ",")
    }

    private var completedFloorCount: Int {
        viewModel.deliverySessionState.completedFloorNumbers.intersection(Set(deliveryFloorNumbers)).count
    }

    private var checklistProgress: Double {
        guard !deliveryFloorNumbers.isEmpty else { return 0 }
        return Double(completedFloorCount) / Double(deliveryFloorNumbers.count)
    }

    private var checklistProgressText: String {
        "\(completedFloorCount) / \(deliveryFloorNumbers.count) floors done"
    }

    private var nextUndoneFloor: Int? {
        deliveryFloorNumbers.first { !viewModel.deliverySessionState.completedFloorNumbers.contains($0) }
    }

    private var deliveryUnitLabel: String {
        viewModel.deliveryUnitIsBundles ? "bdl" : "pcs"
    }

    private var activeFloorNumber: Int? {
        nextUndoneFloor ?? deliveryFloorNumbers.last
    }

    private var activeFloorRows: [FloorDistributionRow] {
        guard let activeFloorNumber else { return [] }
        let rows = deliveryRows(for: activeFloorNumber)
        let tripNames = Set(viewModel.currentTripItemNames)
        return tripNames.isEmpty ? rows : rows.filter { tripNames.contains($0.itemName) }
    }

    private var totalRouteUnits: Int {
        let tripNames = Set(viewModel.currentTripItemNames)
        let rows = tripNames.isEmpty
            ? viewModel.deliveryFloorDistributions
            : viewModel.deliveryFloorDistributions.filter { tripNames.contains($0.itemName) }
        return rows.reduce(0) { $0 + deliveryValue(for: $1) }
    }

    private var activeFloorUnits: Int {
        activeFloorRows.reduce(0) { $0 + deliveryValue(for: $1) }
    }

    private var heaviestFloorLoad: (floor: Int, units: Int)? {
        let loads = Dictionary(grouping: viewModel.deliveryFloorDistributions, by: \.floorNumber)
            .mapValues { rows in rows.reduce(0) { $0 + deliveryValue(for: $1) } }
        guard let heaviest = loads.max(by: { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        }) else { return nil }
        return (floor: heaviest.key, units: heaviest.value)
    }

    private var instructionText: String {
        if viewModel.deliveryUnitIsBundles {
            return "Deliver the bundle count shown for each floor. Loose pieces are listed separately."
        }
        return "Deliver the piece count shown for each floor. Remainders are assigned to the first floors."
    }

    private var deliverySessionHeaderCard: some View {
        let state = viewModel.deliverySessionState

        return PremiumCard(accentColor: state.isActive ? (state.isPaused ? .orange : .mint) : .blue) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: state.isComplete ? "checkmark.seal.fill" : "figure.walk.motion")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(state.isComplete ? .green : (state.isPaused ? .orange : .mint))
                        .frame(width: 42, height: 42)
                        .background((state.isComplete ? Color.green : (state.isPaused ? Color.orange : Color.mint)).opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(state.isActive ? "Delivery Session" : "Ready to Deliver")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                        Text(sessionSubtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Text("\(completedFloorCount)/\(deliveryFloorNumbers.count)")
                        .font(.headline.weight(.heavy).monospacedDigit())
                        .foregroundStyle(state.isComplete ? .green : .mint)
                        .contentTransition(.numericText())
                }

                HStack(spacing: 8) {
                    floorLoadMetric("Completed", "\(completedFloorCount)", "floors", tint: .mint)
                    floorLoadMetric("Remaining", "\(max(deliveryFloorNumbers.count - completedFloorCount, 0))", "floors", tint: .blue)
                    floorLoadMetric("Target", targetCountdownText, "finish", tint: .orange)
                }

                sessionControls
                currentTripCard
                nextCarryGroupPicker
            }
        }
    }

    private var sessionSubtitle: String {
        guard let tower = viewModel.selectedTower else { return "Select a tower to start delivery." }
        let state = viewModel.deliverySessionState

        if state.isComplete {
            return "\(tower.name) route complete. Save the daily log when ready."
        }
        if state.isPaused {
            return "\(tower.name) paused. Resume when you are moving again."
        }
        if state.isActive {
            return "\(tower.name) active. Checklist updates the widget and Live Activity."
        }
        return "\(tower.name) has \(deliveryFloorNumbers.count) delivery floors ready for checklist tracking."
    }

    private var targetCountdownText: String {
        let target = shiftSettings.targetTime(for: .now)
        let seconds = Int(target.timeIntervalSinceNow)
        if seconds <= 0 { return "Due" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(max(minutes, 1))m"
    }

    private var sessionControls: some View {
        HStack(spacing: 8) {
            if viewModel.deliverySessionState.isActive {
                checklistAction(viewModel.deliverySessionState.isPaused ? "Resume" : "Pause", systemImage: viewModel.deliverySessionState.isPaused ? "play.fill" : "pause.fill") {
                    if viewModel.deliverySessionState.isPaused {
                        viewModel.resumeDeliverySession()
                    } else {
                        viewModel.pauseDeliverySession()
                    }
                }
                checklistAction("Finish", systemImage: "flag.checkered") {
                    viewModel.finishDeliverySession()
                }
            } else {
                checklistAction("Start Session", systemImage: "play.fill") {
                    viewModel.startDeliverySession()
                }
                checklistAction("Set First Carry", systemImage: "shippingbox.fill") {
                    viewModel.setNextCarryGroup(viewModel.carryGroups.first.map { carryGroupTitle($0) })
                }
            }
        }
    }

    private var currentTripCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isCurrentTripExpanded.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.mint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Trip")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white.opacity(0.86))
                        if viewModel.currentTripItemNames.isEmpty {
                            Text("Choose up to 2 items · Tap to select")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        } else {
                            Text(viewModel.currentTripItemNames.joined(separator: " + "))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.mint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                    }

                    Spacer(minLength: 8)

                    if !viewModel.currentTripItemNames.isEmpty {
                        Text("\(viewModel.currentTripItemNames.count)/2")
                            .font(.caption2.weight(.heavy).monospacedDigit())
                            .foregroundStyle(.mint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.mint.opacity(0.14), in: Capsule())
                    }

                    Image(systemName: isCurrentTripExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.42))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(currentTripAccessibilityLabel)
            .accessibilityHint(isCurrentTripExpanded ? "Double tap to collapse." : "Double tap to change.")

            if isCurrentTripExpanded {
                VStack(spacing: 6) {
                    ForEach(viewModel.availableCurrentTripItems) { summary in
                        currentTripItemRow(summary)
                    }

                    if !viewModel.currentTripItemNames.isEmpty {
                        Button {
                            viewModel.clearCurrentTripItems()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle")
                                    .font(.caption2.weight(.bold))
                                Text("Clear selection")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.snappy(duration: 0.2), value: isCurrentTripExpanded)
    }

    private var currentTripAccessibilityLabel: String {
        if viewModel.currentTripItemNames.isEmpty {
            return "Current Trip, no items selected."
        }
        let names = viewModel.currentTripItemNames.joined(separator: " and ")
        return "Current Trip, \(names) selected, \(viewModel.currentTripItemNames.count) of 2 items."
    }

    private var nextFloorLoadAccessibilityLabel: String {
        if let floor = nextUndoneFloor {
            return "Current floor focus, floor \(floor), \(activeFloorUnits) \(deliveryUnitLabel), \(activeFloorRows.count) items, \(completedFloorCount) of \(deliveryFloorNumbers.count) floors complete."
        }
        return "Route complete, all \(deliveryFloorNumbers.count) floors delivered."
    }

    private var nextFloorFocusAccessibilityLabel: String {
        if let floor = nextUndoneFloor {
            return "Mark floor \(floor) complete"
        }
        return "All floors complete"
    }

    private func currentTripItemRow(_ summary: CalculationSummary) -> some View {
        let isSelected = viewModel.currentTripItemNames.contains(summary.itemName)
        let isFull = viewModel.currentTripItemNames.count >= 2
        let isDisabled = !isSelected && isFull

        return Button {
            viewModel.toggleCurrentTripItem(summary.itemName)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? .mint : .white.opacity(isDisabled ? 0.25 : 0.48))

                LinenItemIcon(itemName: summary.itemName, size: 26, boxed: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.itemName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(isDisabled ? 0.4 : 0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text("\(summary.deliverableBundles > 0 ? summary.deliverableBundles : summary.fullBundles) bdl · \(summary.receivedPieces) pcs")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(isDisabled ? 0.3 : 0.55))
                }

                Spacer(minLength: 8)

                if isDisabled {
                    Text("Full")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                (isSelected ? Color.mint : Color.white).opacity(isSelected ? 0.12 : 0.04),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke((isSelected ? Color.mint : Color.white).opacity(isSelected ? 0.38 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(ChecklistButtonStyle())
        .disabled(isDisabled)
        .accessibilityLabel("\(summary.itemName), \(summary.deliverableBundles > 0 ? summary.deliverableBundles : summary.fullBundles) bundles, \(isSelected ? "selected" : "not selected").")
        .accessibilityHint(isDisabled ? "Only two items can be selected for one trip." : isSelected ? "Double tap to deselect." : "Double tap to select for current trip.")
    }

    @ViewBuilder
    private var nextCarryGroupPicker: some View {
        let groups = viewModel.carryGroups
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(.blue)
                    Text("Next Carry")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                    if let title = viewModel.deliverySessionState.nextCarryGroupTitle {
                        Text(title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.blue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(groups) { group in
                            carryGroupButton(group)
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
        }
    }

    private func carryGroupButton(_ group: CarryGroup) -> some View {
        let title = carryGroupTitle(group)
        let isSelected = viewModel.deliverySessionState.nextCarryGroupTitle == title
        return Button {
            viewModel.setNextCarryGroup(title)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: group.carryType == .physicalBin ? "shippingbox.fill" : "square.stack.3d.up.fill")
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background((isSelected ? Color.blue : Color.white).opacity(isSelected ? 0.2 : 0.06), in: Capsule())
            .overlay(Capsule().stroke((isSelected ? Color.blue : Color.white).opacity(isSelected ? 0.46 : 0.1), lineWidth: 1))
        }
        .buttonStyle(ChecklistButtonStyle())
    }

    private func carryGroupTitle(_ group: CarryGroup) -> String {
        "\(group.label) · \(group.count)"
    }

    private var nextFloorLoadCard: some View {
        PremiumCard(accentColor: .blue) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: nextUndoneFloor == nil ? "checkmark.seal.fill" : "figure.walk.arrival")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(nextUndoneFloor == nil ? .green : .blue)
                        .frame(width: 42, height: 42)
                        .background((nextUndoneFloor == nil ? Color.green : Color.blue).opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(nextUndoneFloor.map { "Next floor load: \($0)" } ?? "Route complete")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(nextFloorLoadMessage)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(activeFloorUnits)")
                            .font(.title2.weight(.heavy).monospacedDigit())
                            .foregroundStyle(nextUndoneFloor == nil ? .green : .blue)
                            .contentTransition(.numericText())
                        Text(deliveryUnitLabel)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.48))
                    }
                }

                HStack(spacing: 8) {
                    floorLoadMetric("This floor", "\(activeFloorUnits)", deliveryUnitLabel, tint: .blue)
                    floorLoadMetric("Floors", "\(deliveryFloorNumbers.count)", "\(completedFloorCount) done", tint: .cyan)
                    floorLoadMetric("Route total", "\(totalRouteUnits)", deliveryUnitLabel, tint: .green)
                }

                HStack(spacing: 8) {
                    if let heaviestFloorLoad {
                        floorLoadMetric("Heaviest", "F\(heaviestFloorLoad.floor)", "\(heaviestFloorLoad.units) \(deliveryUnitLabel)", tint: .orange)
                    } else {
                        floorLoadMetric("Heaviest", "-", deliveryUnitLabel, tint: .white)
                    }
                    floorLoadMetric("Remaining", "\(max(deliveryFloorNumbers.count - completedFloorCount, 0))", "floors", tint: nextUndoneFloor == nil ? .green : .blue)
                    floorLoadMetric("Items", "\(activeFloorRows.count)", "this floor", tint: .white)
                }

                if activeFloorRows.isEmpty {
                    let hasTrip = !viewModel.currentTripItemNames.isEmpty
                    let emptyMessage: String = {
                        if nextUndoneFloor == nil {
                            return "All listed floors are marked complete."
                        }
                        if hasTrip {
                            return "No trip items (\(viewModel.currentTripItemNames.joined(separator: ", "))) are listed for this floor."
                        }
                        return "No deliverable items are listed for this floor."
                    }()
                    Text(emptyMessage)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    VStack(spacing: 7) {
                        ForEach(activeFloorRows.prefix(5)) { row in
                            floorLoadRow(row)
                        }
                        if activeFloorRows.count > 5 {
                            Text("+ \(activeFloorRows.count - 5) more item\(activeFloorRows.count - 5 == 1 ? "" : "s") on this floor")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nextFloorLoadAccessibilityLabel)
        .accessibilityAddTraits(.isHeader)
    }

    private var nextFloorLoadMessage: String {
        if nextUndoneFloor == nil {
            return "All checklist floors are complete. Save the daily log when the shift is done."
        }
        let hasTrip = !viewModel.currentTripItemNames.isEmpty
        let tripSuffix = hasTrip ? " Showing current trip items only." : ""
        if viewModel.deliveryUnitIsBundles {
            return "Bundle-first pickup list for the next unchecked floor." + tripSuffix
        }
        return "Piece-count pickup list for the next unchecked floor." + tripSuffix
    }

    private func floorLoadMetric(_ label: String, _ value: String, _ detail: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.52))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(tint.opacity(tint == .white ? 0.045 : 0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(tint.opacity(tint == .white ? 0.07 : 0.18), lineWidth: 1)
        )
    }

    private func floorLoadRow(_ row: FloorDistributionRow) -> some View {
        let isActive = viewModel.currentDeliveryItemName == row.itemName
        let tint = isActive ? Color.mint : Color.blue

        return Button {
            viewModel.selectCurrentDeliveryItem(row.itemName)
        } label: {
            HStack(spacing: 10) {
                LinenItemIcon(itemName: row.itemName, size: 28, boxed: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.itemName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    Text(perFloorDeltaText(for: row))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(plannedAmountText(for: row))
                        .font(.caption.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    deltaBadge(for: row)
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(tint.opacity(isActive ? 0.13 : 0.045), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(tint.opacity(isActive ? 0.45 : 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(ChecklistButtonStyle())
        .accessibilityLabel("Show \(row.itemName) in the delivery widget")
    }

    private func plannedAmountText(for row: FloorDistributionRow) -> String {
        let value = deliveryValue(for: row)
        if viewModel.deliveryUnitIsBundles, let item = item(for: row.itemName), item.bundleSize > 0 {
            return "\(value) bdl · \(value * item.bundleSize) pcs"
        }
        return "\(value) \(deliveryUnitLabel)"
    }

    private func perFloorDeltaText(for row: FloorDistributionRow) -> String {
        let par = parValue(for: row)
        let delta = deliveryValue(for: row) - par
        return "Par \(par) · Δ \(delta > 0 ? "+\(delta)" : "\(delta)")"
    }

    private func parValue(for row: FloorDistributionRow) -> Int {
        max(0, item(for: row.itemName)?.parCount ?? 0)
    }

    private func deltaBadge(for row: FloorDistributionRow) -> some View {
        let delta = deliveryValue(for: row) - parValue(for: row)
        let color: Color = delta == 0 ? .green : (delta < 0 ? .orange : .blue)
        let label = delta == 0 ? "Exact" : (delta < 0 ? "Short \(abs(delta))" : "Over \(delta)")
        return Text(label)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.24), lineWidth: 1))
    }

    private func deliveryValue(for row: FloorDistributionRow) -> Int {
        if viewModel.deliveryUnitIsBundles {
            return row.suggestedBundles ?? row.suggestedPieces
        }
        return row.suggestedPieces
    }

    private var deliveryChecklistCard: some View {
        PremiumCard(accentColor: .green) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "checklist.checked")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delivery Checklist")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(checklistProgressText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    Spacer()

                    Text("\(Int((checklistProgress * 100).rounded()))%")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.14), in: Capsule())

                    Menu {
                        Button {
                            for floor in deliveryFloorNumbers {
                                viewModel.markFloorComplete(floor)
                            }
                        } label: {
                            Label("Mark All Complete", systemImage: "checkmark.circle.fill")
                        }
                        Button(role: .destructive) {
                            showChecklistClearConfirmation = true
                        } label: {
                            Label("Clear Completed Floors", systemImage: "xmark.circle.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .accessibilityLabel("More checklist actions")
                }

                nextFloorFocus
                activeDeliveryItemStatus

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.mint, Color.green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * checklistProgress)
                    }
                }
                .frame(height: 6)

                VStack(spacing: 8) {
                    ForEach(deliveryFloorNumbers, id: \.self) { floor in
                        floorToggle(floor)
                    }
                }
            }
        }
    }

    private var activeDeliveryItemStatus: some View {
        let hasTrip = !viewModel.currentTripItemNames.isEmpty
        let tripLabel = hasTrip
            ? viewModel.currentTripItemNames.joined(separator: " + ")
            : nil

        return HStack(spacing: 10) {
            Image(systemName: hasTrip ? "dot.radiowaves.left.and.right" : "shippingbox.and.arrow.backward")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(hasTrip ? .mint : .blue)
                .frame(width: 34, height: 34)
                .background((hasTrip ? Color.mint : Color.blue).opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(tripLabel ?? "Choose current trip items")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(hasTrip ? "Widget and floor plan follow these items." : "Select up to 2 items in Current Trip above.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 8)

            Text(hasTrip ? "Live" : "Select")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(hasTrip ? .mint : .blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background((hasTrip ? Color.mint : Color.blue).opacity(0.13), in: Capsule())
        }
        .padding(12)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke((hasTrip ? Color.mint : Color.blue).opacity(0.18), lineWidth: 1)
        )
    }

    private var rebalanceEntryCard: some View {
        Button {
            path.append(FlowStep.rebalance(itemName: nil))
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("I Ran Out / Rebalance")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Collect from floors with extra and deliver to short floors")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(12)
            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.orange.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var nextFloorFocus: some View {
        Button {
            markNextFloorComplete()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: nextUndoneFloor == nil ? "checkmark.seal.fill" : "arrow.down.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(nextUndoneFloor == nil ? .green : .white)
                    .frame(width: 38, height: 38)
                    .background((nextUndoneFloor == nil ? Color.green : Color.blue).opacity(0.18), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(nextUndoneFloor.map { "Next Floor \($0)" } ?? "All Floors Complete")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(nextUndoneFloor == nil ? "Checklist is complete." : "Tap after this floor is delivered.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer()

                Image(systemName: nextUndoneFloor == nil ? "checkmark" : "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [
                        (nextUndoneFloor == nil ? Color.green : Color.blue).opacity(0.18),
                        Color.white.opacity(0.055)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke((nextUndoneFloor == nil ? Color.green : Color.blue).opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(ChecklistButtonStyle())
        .disabled(nextUndoneFloor == nil)
        .accessibilityLabel(nextFloorFocusAccessibilityLabel)
        .accessibilityHint(nextUndoneFloor == nil ? "" : "Double tap after this floor is delivered.")
    }

    private func checklistAction(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
        }
        .buttonStyle(ChecklistButtonStyle())
        .foregroundStyle(.white)
        .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    private func floorToggle(_ floor: Int) -> some View {
        let isDone = viewModel.deliverySessionState.completedFloorNumbers.contains(floor)
        let rows = deliveryRows(for: floor)
        let tripNames = Set(viewModel.currentTripItemNames)
        let displayRows = tripNames.isEmpty ? rows : rows.filter { tripNames.contains($0.itemName) }
        let floorUnits = displayRows.reduce(0) { $0 + deliveryValue(for: $1) }
        return Button {
            toggleFloor(floor)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(isDone ? .green : .white.opacity(0.48))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Floor \(floor)")
                        .font(.subheadline.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.white)
                    Text(floorQuantitySummary(for: rows))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(isDone ? 0.42 : 0.62))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 8)

                Text(displayRows.isEmpty ? "-" : "\(floorUnits) \(deliveryUnitLabel)")
                    .font(.caption.weight(.heavy).monospacedDigit())
                    .foregroundStyle(isDone ? .green : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background((isDone ? Color.green : Color.blue).opacity(isDone ? 0.18 : 0.13), in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(
                isDone ? Color.green.opacity(0.12) : Color.white.opacity(0.055),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isDone ? Color.green.opacity(0.34) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(ChecklistButtonStyle())
        .accessibilityLabel(isDone ? "Floor \(floor) complete" : "Floor \(floor), \(floorUnits) \(deliveryUnitLabel)")
        .accessibilityHint(isDone ? "Double tap to unmark." : "Double tap to mark complete.")
    }

    private func toggleFloor(_ floor: Int) {
        if viewModel.deliverySessionState.completedFloorNumbers.contains(floor) {
            viewModel.unmarkFloorComplete(floor)
        } else {
            viewModel.markFloorCompleteAndAdvance(floor)
        }
    }

    private func markNextFloorComplete() {
        guard let next = deliveryFloorNumbers.first(where: { !viewModel.deliverySessionState.completedFloorNumbers.contains($0) }) else { return }
        viewModel.markFloorCompleteAndAdvance(next)
    }

    private func deliveryRows(for floor: Int) -> [FloorDistributionRow] {
        if usesIndexedFloorSequence, let sequenceIndex = deliveryFloorNumbers.firstIndex(of: floor) {
            let sourceFloorNumber = sequenceIndex + 1
            return sortedDeliveryRows(viewModel.deliveryFloorDistributions.filter { $0.floorNumber == sourceFloorNumber && deliveryValue(for: $0) > 0 })
        }

        return sortedDeliveryRows(viewModel.deliveryFloorDistributions.filter { $0.floorNumber == floor && deliveryValue(for: $0) > 0 })
    }

    private var usesIndexedFloorSequence: Bool {
        deliveryFloorNumbers != Array(1...max(deliveryFloorNumbers.count, 1))
    }

    private func sortedDeliveryRows(_ rows: [FloorDistributionRow]) -> [FloorDistributionRow] {
        rows
            .sorted { lhs, rhs in
                let leftValue = deliveryValue(for: lhs)
                let rightValue = deliveryValue(for: rhs)
                if leftValue == rightValue {
                    return lhs.itemName < rhs.itemName
                }
                return leftValue > rightValue
            }
    }

    private func floorQuantitySummary(for rows: [FloorDistributionRow]) -> String {
        let tripNames = Set(viewModel.currentTripItemNames)
        let filtered = tripNames.isEmpty ? rows : rows.filter { tripNames.contains($0.itemName) }
        guard !filtered.isEmpty else {
            return tripNames.isEmpty ? "No listed delivery items" : "No trip items on this floor"
        }
        let visible = filtered.prefix(3).map { row in
            "\(row.itemName): \(deliveryValue(for: row)) \(deliveryUnitLabel)"
        }
        let suffix = filtered.count > 3 ? " +\(filtered.count - 3) more" : ""
        return visible.joined(separator: " · ") + suffix
    }

    private func summary(for itemName: String) -> CalculationSummary? {
        viewModel.calculationSummaries.first { $0.itemName == itemName }
    }

    private func item(for itemName: String) -> LinenItem? {
        viewModel.availableItems.first { $0.name == itemName }
    }

    @ViewBuilder
    private var loosePiecesFooter: some View {
        let items = viewModel.calculationSummaries.filter { $0.loosePieces > 0 }
        if !items.isEmpty {
            PremiumCard(accentColor: .orange) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill").foregroundStyle(.orange)
                        Text("Loose pieces (not in bundles)").font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    ForEach(items) { item in
                        HStack {
                            Text(item.itemName).font(.caption).foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text("\(item.loosePieces) pcs")
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
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

private struct ChecklistButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Card

private struct FloorPlanCard: View {
    let group: FloorRangeGroup
    let summary: CalculationSummary?
    let item: LinenItem?
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        PremiumCard(accentColor: LinenIconLibrary.color(forItem: group.itemName)) {
            VStack(alignment: .leading, spacing: 14) {
                Button(action: onToggle) {
                    VStack(alignment: .leading, spacing: 10) {
                        header
                        if isExpanded {
                            Text("\(group.ranges.count) grouped delivery range\(group.ranges.count == 1 ? "" : "s")")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        } else {
                            rangeRows(Array(group.ranges.prefix(2)))
                            if group.ranges.count > 2 {
                                Text("+ \(group.ranges.count - 2) more grouped range\(group.ranges.count - 2 == 1 ? "" : "s")")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(group.itemName), \(group.ranges.count) grouped delivery ranges.")
                .accessibilityHint(isExpanded ? "Double tap to collapse delivery details." : "Double tap for all delivery details.")

                if isExpanded {
                    Divider().overlay(Color.white.opacity(0.08))
                    conversionSummary
                    if group.ranges.contains(where: \.isPlusOne) {
                        Text("+1 badges mark the floor ranges receiving the remainder.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    Text("All grouped ranges")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                    rangeRows(group.ranges)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.snappy(duration: 0.2), value: isExpanded)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            LinenItemIcon(itemName: group.itemName, size: 42, boxed: true)
            VStack(alignment: .leading, spacing: 3) {
                Text(group.itemName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                if let item, item.bundleSize > 0 {
                    Text("Bundle size: \(item.bundleSize) pcs")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Spacer()
            if let summary {
                StatusBadge(status: summary.status)
            }
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    private func rangeRows(_ ranges: [FloorRange]) -> some View {
        VStack(spacing: 8) {
            ForEach(ranges) { range in
                rangeRow(range)
            }
        }
    }

    private func rangeRow(_ range: FloorRange) -> some View {
        let ratio = fillRatio(for: range)
        let gaugeColor = Self.gaugeColor(ratio: ratio)

        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(range.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text(floorCountLabel(for: range))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.48))
                }

                Spacer()

                Text(valueLabel(range.suggestedValue))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(gaugeColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .contentTransition(.numericText())

                if group.unitIsBundles, let par = item?.parCount, par > 0 {
                    let delta = range.suggestedValue - par
                    if delta != 0 {
                        Text(delta > 0 ? "+\(delta)" : "\(delta)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(delta > 0 ? Color.green.opacity(0.9) : Color.orange.opacity(0.9))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background((delta > 0 ? Color.green : Color.orange).opacity(0.14), in: Capsule())
                    }
                }

                Text("\(floorCount(for: range))")
                    .font(.caption2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(minWidth: 22)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.075), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))

                if range.isPlusOne {
                    Text("+1")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(gaugeColor.opacity(0.22), in: Capsule())
                        .foregroundStyle(gaugeColor)
                }
            }
            .padding(.top, 7)
            .padding(.horizontal, 10)
            .padding(.bottom, 6)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        colors: Self.spectrumColors.map { $0.opacity(0.18) },
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(Capsule())

                    LinearGradient(
                        colors: [Self.spectrumColors[0], gaugeColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(Capsule())
                    .frame(width: max(6, proxy.size.width * CGFloat(min(ratio, 1.0))))
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
        .background(gaugeColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(gaugeColor.opacity(0.22), lineWidth: 1)
        )
    }

    private var conversionSummary: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                fact("Received", value: "\(summary?.receivedPieces ?? 0)", detail: "pcs")
                fact("Bundles", value: "\(summary?.fullBundles ?? 0)", detail: looseDetail, emphasis: true)
                if group.unitIsBundles {
                    fact("Par", value: parValue, detail: "per floor")
                } else if let summary {
                    let bpf = summary.basePerFloorPieces
                    let inIdeal = bpf >= 20 && bpf <= 25
                    fact("Per Floor", value: "\(bpf)", detail: inIdeal ? "ideal ✓" : "pcs", emphasis: inIdeal)
                } else {
                    fact("Rule", value: "No Par", detail: "timeshare")
                }
            }
            if group.unitIsBundles, let summary {
                HStack(spacing: 8) {
                    fact("Can Deliver", value: "\(summary.deliverableBundles)", detail: "bundles", emphasis: true)
                    fact("Shortage", value: "\(summary.shortageBundles)", detail: "bundles")
                    fact("Leftover", value: "\(summary.leftoverBundles)", detail: "bundles")
                }
            }
            if !group.unitIsBundles, let summary, summary.remainderPieces > 0 {
                HStack(spacing: 8) {
                    fact("+1 Floors", value: "\(summary.remainderPieces)", detail: "get extra pcs", emphasis: false)
                    fact("High Floor", value: "\(summary.basePerFloorPieces + 1)", detail: "pcs", emphasis: false)
                }
            }
            if !group.unitIsBundles, let summary {
                morningReserveFact(for: summary)
            }
        }
    }

    private func morningReserveFact(for summary: CalculationSummary) -> some View {
        let result = TimeshareReserveAlgorithm.evaluate(reservePieces: summary.remainderPieces)
        let style = morningReserveStyle(for: result.status)
        return HStack(spacing: 8) {
            Image(systemName: style.symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(style.color)
                .frame(width: 24, height: 24)
                .background(style.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(result.status.displayName)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                Text(result.status.detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.54))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
            Spacer(minLength: 8)
            Text("\(result.reservePieces) pcs")
                .font(.caption.weight(.heavy).monospacedDigit())
                .foregroundStyle(style.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(style.color.opacity(0.13), in: Capsule())
        }
        .padding(9)
        .background(style.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(style.color.opacity(0.18), lineWidth: 1)
        )
    }

    private func morningReserveStyle(for status: TimeshareReserveStatus) -> (color: Color, symbol: String) {
        switch status {
        case .exact:
            return (.green, "checkmark.circle.fill")
        case .lowReserve:
            return (.orange, "exclamationmark.triangle.fill")
        case .idealMorningReserve:
            return (.mint, "sunrise.fill")
        case .overReserve:
            return (.blue, "arrow.up.circle.fill")
        }
    }

    private var looseDetail: String {
        guard let summary, summary.loosePieces > 0 else { return "full" }
        return "+\(summary.loosePieces) loose"
    }

    private var parValue: String {
        guard let item else { return "0" }
        return group.unitIsBundles ? "\(item.parCount)" : "\(item.parCount) pcs"
    }

    private func fact(_ label: String, value: String, detail: String, emphasis: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(emphasis ? .blue : .white)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .padding(.horizontal, 8)
        .background(
            emphasis ? Color.blue.opacity(0.16) : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func valueLabel(_ v: Int) -> String {
        if group.unitIsBundles {
            let bundleSize = item?.bundleSize ?? 0
            if bundleSize > 0 {
                let pcs = v * bundleSize
                return v == 1 ? "1 bdl · \(pcs) pcs" : "\(v) bdl · \(pcs) pcs"
            }
            return v == 1 ? "1 bundle" : "\(v) bundles"
        }
        return "\(v) pcs"
    }

    private func floorCount(for range: FloorRange) -> Int {
        max(range.lastFloor - range.firstFloor + 1, 1)
    }

    private func floorCountLabel(for range: FloorRange) -> String {
        let count = floorCount(for: range)
        return count == 1 ? "1 floor" : "\(count) floors"
    }

    private func fillRatio(for range: FloorRange) -> Double {
        guard group.unitIsBundles else { return 1.0 }
        guard let par = item?.parCount, par > 0 else { return 1.0 }
        return Double(range.suggestedValue) / Double(par)
    }

    // Red → orange → yellow → yellow-green → green
    private static let spectrumColors: [Color] = [
        Color(hue: 0.00, saturation: 0.82, brightness: 0.88),
        Color(hue: 0.08, saturation: 0.86, brightness: 0.90),
        Color(hue: 0.17, saturation: 0.84, brightness: 0.92),
        Color(hue: 0.25, saturation: 0.78, brightness: 0.90),
        Color(hue: 0.33, saturation: 0.72, brightness: 0.86),
    ]

    private static func gaugeColor(ratio: Double) -> Color {
        let clamped = min(max(ratio, 0.0), 1.0)
        return Color(hue: clamped * (120.0 / 360.0), saturation: 0.78, brightness: 0.88)
    }
}
