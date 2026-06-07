import SwiftUI

struct ShiftCommandCenterView: View {
    @Environment(FlowViewModel.self) private var viewModel
    @Environment(ShiftSettings.self) private var shiftSettings

    @State private var now = Date.now
    @State private var completedTripSequences: Set<Int> = []
    @State private var showCompletedFloorsResetConfirmation = false

    private let paceEngine = DeliveryPaceEngine()
    private let doorPlanner = DoorOpeningPassPlanner()
    private let tripPlanner = ElevatorTripPlanner()
    private let rebalanceEngine = SmartRebalanceEngine()
    private let tripItemLimit = 2

    var body: some View {
        AppBackground(accentColor: towerColor) {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        header

                        if viewModel.selectedTower == nil || viewModel.calculationSummaries.isEmpty {
                            emptyOperationalState
                        } else {
                            ShiftAlertCenterView(session: session, alertText: paceAlert, now: now)
                            if allowsStrategyPlanning {
                                recommendedNextAction
                                carryGroupsSection
                                doorOpeningCard
                                elevatorTripSection
                                rebalanceSection
                            } else {
                                timesharePolicyCard
                            }
                            tripItemSelectorCard
                            completedFloorControls
                            FloorChecklistView(
                                floorNumbers: floorNumbers,
                                completedFloorNumbers: deliveredFloorNumbers,
                                bundlesPerFloor: bundlesPerFloor,
                                itemParsByFloor: selectedItemParsByFloor,
                                onToggleFloor: { floor in
                                    if deliveredFloorNumbers.contains(floor) {
                                        viewModel.unmarkFloorComplete(floor)
                                    } else {
                                        viewModel.markFloorCompleteAndAdvance(floor)
                                    }
                                },
                                onResetCurrentPhase: resetCompletedFloors,
                                onReset: resetCompletedFloors
                            )
                            if allowsStrategyPlanning {
                                liveActivityFoundationCard
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 44)
                }
            }
        }
        .navigationTitle("Live Delivery")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            while !Task.isCancelled {
                now = .now
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .onChange(of: floorSignature) { _, _ in
            completedTripSequences = []
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "command.circle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background((towerColor ?? .blue).opacity(0.72), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Live Delivery")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer()

            Button {
                toggleCommandSession()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: commandSessionButtonImage)
                    Text(commandSessionButtonTitle)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(commandSessionButtonColor.opacity(0.72), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 2)
    }

    private var emptyOperationalState: some View {
        PremiumCard(accentColor: .blue) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "shippingbox.and.arrow.backward")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.blue)
                Text("Build the linen plan first")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Select a tower and enter received linen in Flow. Live Delivery will turn the calculated plan into pace, trip, door-pass, and checklist guidance.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recommendedNextAction: some View {
        PremiumCard(accentColor: session.paceStatus == .behind ? .orange : .green) {
            HStack(spacing: 11) {
                Image(systemName: "sparkles")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended Next Action")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))
                    Text(nextActionText)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
                Spacer()
            }
        }
    }

    private var timesharePolicyCard: some View {
        PremiumCard(accentColor: .blue) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 11) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Timeshare Workflow")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Strategy cards are off for this tower.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    commandFact("\(floorNumbers.count)", "floors", tint: .blue)
                    commandFact("\(session.remainingFloors.count)", "left", tint: .green)
                    commandFact(session.estimatedCompletionTime?.formatted(date: .omitted, time: .shortened) ?? "--", "finish", tint: .cyan)
                }
            }
        }
    }

    @ViewBuilder
    private var tripItemSelectorCard: some View {
        if !tripSelectorItems.isEmpty {
            PremiumCard(accentColor: .cyan) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Item Selector")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                            Text("\(viewModel.currentTripItemNames.count)/\(tripItemLimit) selected")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(1)
                                .minimumScaleFactor(0.74)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if !viewModel.currentTripItemNames.isEmpty {
                            Button("Clear") {
                                viewModel.clearCurrentTripItems()
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.72))
                            .buttonStyle(.plain)
                            .lineLimit(1)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                        ForEach(tripSelectorItems, id: \.itemName) { summary in
                            tripItemCard(summary)
                        }
                    }
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }
            }
        }
    }

    private var completedFloorControls: some View {
        PremiumCard(accentColor: .green) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Completed Floors")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(deliveredFloorNumbers.count) of \(session.totalFloors)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                }

                Spacer()

                HStack(spacing: 8) {
                    commandIconButton(systemImage: "minus") {
                        markPreviousFloorPending()
                    }
                    Text("\(deliveredFloorNumbers.count)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 34)
                    commandIconButton(systemImage: "plus") {
                        markNextFloorDelivered()
                    }
                }

                Button("Reset") {
                    showCompletedFloorsResetConfirmation = true
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
                .buttonStyle(.plain)
            }
        }
        .confirmationDialog("Reset completed floors?", isPresented: $showCompletedFloorsResetConfirmation, titleVisibility: .visible) {
            Button("Reset Completed Floors", role: .destructive) {
                resetCompletedFloors()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This clears the live shift floor progress and trip completion marks. Saved daily logs are not deleted.")
        }
    }

    @ViewBuilder
    private var carryGroupsSection: some View {
        if !viewModel.carryGroups.isEmpty {
            PremiumCard(accentColor: .mint) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Carry Groups")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("\(viewModel.carryGroups.count) logistics groups")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                        }

                        Spacer()

                        Text("\(viewModel.carryGroups.count)")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(.mint)
                    }

                    ForEach(viewModel.carryGroups.prefix(4)) { group in
                        carryGroupRow(group)
                    }

                    if viewModel.carryGroups.count > 4 {
                        Text("+ \(viewModel.carryGroups.count - 4) more carry groups")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.50))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var doorOpeningCard: some View {
        if let recommendation = doorPlanner.recommendation(summaries: viewModel.calculationSummaries, deliveryRows: viewModel.deliveryFloorDistributions) {
            PremiumCard(accentColor: LinenIconLibrary.color(forItem: recommendation.itemName)) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Text("Door Opening Pass")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.cyan.opacity(0.14), in: Capsule())
                        Spacer()
                    }
                    HStack(spacing: 10) {
                        LinenItemIcon(itemName: recommendation.itemName, size: 42, boxed: true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recommended Door Opening Item")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.56))
                            Text(recommendation.itemName)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    Text(recommendation.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }

    private var elevatorTripSection: some View {
        PremiumCard(accentColor: .indigo) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Elevator Trip Planner")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(tripPlan.efficiencyText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    Spacer()
                    Text("\(remainingTripCount)")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(.indigo)
                }

                ForEach(tripPlan.trips.prefix(5)) { trip in
                    tripRow(trip)
                }

                if tripPlan.trips.count > 5 {
                    Text("+ \(tripPlan.trips.count - 5) more planned trips")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.50))
                }
            }
        }
    }

    private func tripRow(_ trip: ElevatorTrip) -> some View {
        let isDone = completedTripSequences.contains(trip.sequence)
        return Button {
            if isDone {
                completedTripSequences.remove(trip.sequence)
            } else {
                completedTripSequences.insert(trip.sequence)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isDone ? .green : .white.opacity(0.48))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trip \(trip.sequence): \(trip.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text(trip.strategyNote)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                Spacer()
                Text("~\(trip.estimatedBundles) bdl")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.70))
            }
            .padding(10)
            .background(Color.white.opacity(isDone ? 0.035 : 0.060), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func tripItemCard(_ summary: CalculationSummary) -> some View {
        let itemName = summary.itemName
        let isSelected = viewModel.currentTripItemNames.contains(itemName)
        let selectionIsFull = viewModel.currentTripItemNames.count >= tripItemLimit
        let isDisabled = !isSelected && selectionIsFull
        let accent = LinenIconLibrary.color(forItem: itemName)

        return Button {
            viewModel.toggleCurrentTripItem(itemName)
        } label: {
            VStack(spacing: 7) {
                LinenItemIcon(itemName: itemName, size: 38, boxed: true)
                Text(itemName)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .padding(.horizontal, 7)
            .background(accent.opacity(isSelected ? 0.22 : 0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? accent.opacity(0.72) : Color.white.opacity(0.09), lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isDisabled ? 0.34 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(isSelected ? "Remove \(itemName) from Live Delivery" : "Add \(itemName) to Live Delivery")
        .accessibilityHint(isDisabled ? "Two items are already selected." : "")
    }

    private func carryGroupRow(_ group: CarryGroup) -> some View {
        HStack(spacing: 10) {
            Image(systemName: carryIcon(for: group.carryType))
                .font(.caption.weight(.bold))
                .foregroundStyle(carryTint(for: group.estimatedWeightClass))
                .frame(width: 28, height: 28)
                .background(carryTint(for: group.estimatedWeightClass).opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(group.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("\(group.carryType.displayName) · \(group.estimatedWeightClass.displayName)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(1)
            }

            Spacer()

            Text("\(group.count)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(10)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var rebalanceSection: some View {
        if !rebalanceSuggestions.isEmpty {
            PremiumCard(accentColor: .orange) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Emergency Rebalance")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(rebalanceSuggestions.count)")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.14), in: Capsule())
                    }

                    ForEach(rebalanceSuggestions) { suggestion in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.itemName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(suggestion.message)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.64))
                            Text("Recovered \(suggestion.piecesRecovered) pcs total")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(suggestion.isRecoverable ? .green : .orange)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
    }

    private var liveActivityFoundationCard: some View {
        PremiumCard(accentColor: .purple) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Widget & Live Activity")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Progress syncs to Home Screen widget, Lock Screen, and Dynamic Island.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                }
                Spacer()
            }
        }
    }

    private var session: ShiftSession {
        paceEngine.makeSession(
            tower: viewModel.selectedTower,
            summaries: viewModel.calculationSummaries,
            deliveryRows: viewModel.deliveryFloorDistributions,
            completedFloors: deliveredFloorNumbers,
            now: now,
            shiftStartTime: shiftWindow.start,
            targetDownTime: targetDownTime,
            expectedShiftEndTime: shiftWindow.end,
            deliveryStartedAt: deliverySessionStartedAt,
            activeTrip: allowsStrategyPlanning ? tripPlan.nextTrip : nil
        )
    }

    private var paceAlert: String {
        if !allowsStrategyPlanning, session.paceStatus == .onPace {
            return "Timeshare strategy cards are off. Track pace and floors only."
        }
        return paceEngine.alertText(for: session, now: now)
    }

    private var tripPlan: ElevatorTripPlan {
        guard allowsStrategyPlanning else {
            return ElevatorTripPlan(trips: [], completedTripIDs: [])
        }
        return tripPlanner.plan(summaries: viewModel.calculationSummaries, entries: viewModel.receivingEntries)
    }

    private var remainingTripCount: Int {
        max(tripPlan.trips.count - completedTripSequences.count, 0)
    }

    private var rebalanceSuggestions: [RebalanceSuggestion] {
        guard allowsStrategyPlanning else { return [] }
        return rebalanceEngine.suggestions(summaries: viewModel.calculationSummaries, deliveryRows: viewModel.deliveryFloorDistributions)
    }

    private var nextActionText: String {
        if !allowsStrategyPlanning {
            return "Continue with pace and floor checklist tracking."
        }
        if session.paceStatus == .behind {
            return paceAlert
        }
        if let trip = tripPlan.trips.first(where: { !completedTripSequences.contains($0.sequence) }) {
            return "Take Trip \(trip.sequence): \(trip.title)."
        }
        return session.recommendedNextAction
    }

    private var shiftWindow: WorkShiftWindow {
        WorkShiftWindow.containing(
            now,
            startHour: shiftSettings.shiftStartHour,
            startMinute: shiftSettings.shiftStartMinute,
            endHour: shiftSettings.shiftEndHour,
            endMinute: shiftSettings.shiftEndMinute
        )
    }

    private var targetDownTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: shiftWindow.start)
        components.hour = shiftSettings.targetHour
        components.minute = shiftSettings.targetMinute
        components.second = 0

        var candidate = Calendar.current.date(from: components) ?? now
        while candidate < shiftWindow.start {
            candidate = Calendar.current.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }

    private var floorNumbers: [Int] {
        Array(Set(viewModel.deliveryFloorDistributions.map(\.floorNumber))).sorted()
    }

    private var bundlesPerFloor: [Int: Int] {
        var totals: [Int: Int] = [:]
        for row in viewModel.deliveryFloorDistributions {
            let bundles = row.suggestedBundles ?? 0
            totals[row.floorNumber, default: 0] += bundles
        }
        return totals
    }

    private var tripSelectorItems: [CalculationSummary] {
        viewModel.availableCurrentTripItems.sorted {
            LinenIconLibrary.itemComesBefore($0.itemName, $1.itemName)
        }
    }

    private var selectedItemParsByFloor: [Int: [DeliveryChecklistItemPar]] {
        let selectedNames = viewModel.currentTripItemNames
        guard !selectedNames.isEmpty else { return [:] }

        let rowsByFloorAndItem = Dictionary(
            grouping: viewModel.deliveryFloorDistributions,
            by: { "\($0.floorNumber)|\($0.itemName)" }
        )
        let itemsByName = Dictionary(uniqueKeysWithValues: viewModel.availableItems.map { ($0.name, $0) })
        let unit = viewModel.deliveryUnitIsBundles ? "bdl" : "pcs"

        return Dictionary(uniqueKeysWithValues: floorNumbers.map { floor in
            let itemPars = selectedNames.map { itemName in
                let key = "\(floor)|\(itemName)"
                let availableAmount = rowsByFloorAndItem[key]?.reduce(0) { partial, row in
                    partial + deliveryAmount(for: row)
                } ?? 0
                let parAmount = max(itemsByName[itemName]?.parCount ?? 0, 0)
                return DeliveryChecklistItemPar(
                    itemName: itemName,
                    availableAmount: availableAmount,
                    parAmount: parAmount,
                    unit: unit
                )
            }
            return (floor, itemPars)
        })
    }

    private var floorSignature: String {
        floorNumbers.map(String.init).joined(separator: ",")
    }

    private var deliveredFloorNumbers: Set<Int> {
        viewModel.deliverySessionState.completedFloorNumbers.intersection(Set(floorNumbers))
    }

    private var deliverySessionStartedAt: Date? {
        viewModel.deliverySessionState.isActive ? viewModel.deliverySessionState.startedAt : nil
    }

    private var commandSessionButtonTitle: String {
        if viewModel.deliverySessionState.isActive, viewModel.deliverySessionState.isPaused {
            return "Resume"
        }
        return viewModel.deliverySessionState.isActive ? "Pause" : "Start"
    }

    private var commandSessionButtonImage: String {
        if viewModel.deliverySessionState.isActive, !viewModel.deliverySessionState.isPaused {
            return "pause.fill"
        }
        return "play.fill"
    }

    private var commandSessionButtonColor: Color {
        if viewModel.deliverySessionState.isActive, !viewModel.deliverySessionState.isPaused {
            return .orange
        }
        return .green
    }

    private var towerColor: Color? {
        viewModel.selectedTower.flatMap { Color(hex: $0.identityColorHex ?? "") }
    }

    private var allowsStrategyPlanning: Bool {
        TowerOperationalPolicy.allowsStrategyPlanning(for: viewModel.selectedTower)
    }

    private var headerSubtitle: String {
        guard let towerName = viewModel.selectedTower?.name else { return "No active tower" }
        let mode = allowsStrategyPlanning ? "strategy enabled" : "timeshare pace mode"
        guard !floorNumbers.isEmpty else { return "\(towerName) · \(mode)" }
        return "\(towerName) · \(session.remainingFloors.count) floors left · \(mode)"
    }

    private func commandFact(_ value: String, _ label: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }

    private func commandIconButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func carryIcon(for carryType: CarryType) -> String {
        switch carryType {
        case .physicalBin: return "shippingbox.fill"
        case .bundleGroup: return "square.stack.3d.up.fill"
        case .looseCarry: return "hand.raised.fill"
        }
    }

    private func carryTint(for weightClass: EstimatedWeightClass) -> Color {
        switch weightClass {
        case .light: return .green
        case .medium: return .cyan
        case .heavy: return .orange
        }
    }

    private func deliveryAmount(for row: FloorDistributionRow) -> Int {
        viewModel.deliveryUnitIsBundles ? (row.suggestedBundles ?? row.suggestedPieces) : row.suggestedPieces
    }

    private func markNextFloorDelivered() {
        guard let next = floorNumbers.first(where: { floor in
            !deliveredFloorNumbers.contains(floor)
        }) else { return }
        viewModel.markFloorCompleteAndAdvance(next)
    }

    private func markPreviousFloorPending() {
        guard let previous = floorNumbers.reversed().first(where: { floor in
            deliveredFloorNumbers.contains(floor)
        }) else { return }
        viewModel.unmarkFloorComplete(previous)
    }

    private func resetCompletedFloors() {
        for floor in floorNumbers {
            viewModel.unmarkFloorComplete(floor)
        }
    }

    private func toggleCommandSession() {
        if viewModel.deliverySessionState.isActive {
            if viewModel.deliverySessionState.isPaused {
                viewModel.resumeDeliverySession()
            } else {
                viewModel.pauseDeliverySession()
            }
        } else {
            viewModel.startDeliverySession()
        }
    }

}
