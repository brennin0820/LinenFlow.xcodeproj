// Legacy linen/delivery sections previously shown on the Shift tab.
// Preserved for reference or future wiring on the Linen tab — not used in navigation.
import SwiftUI
import SwiftData

struct ShiftTabLegacyDeliveryArchive: View {
    @Environment(FlowViewModel.self) private var flowVM
    @Environment(ShiftSettings.self) private var shiftSettings
    @Environment(WidgetDeepLinkCoordinator.self) private var deepLinkCoordinator
    @Environment(\.modelContext) private var modelContext

    @State private var plannerViewModel = SmartShiftAlarmPlannerViewModel()
    @State private var showDeliveryCommandCenter = false
    @State private var wifiService = WiFiLeaveDetectionService()
    @State private var now = Date.now
    @State private var isTimingExpanded = false
    @State private var isNotesExpanded = false
    @State private var isSummaryExpanded = false
    @State private var selectedDeliverableFloor: Int?
    @State private var savedConfirmation: String?
    @State private var savedAt: Date?

    @State private var isPaceExpanded = true

    var body: some View {
        NavigationStack {
            AppBackground {
                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: 14) {
                            shiftHeaderCard
                            timingCard

                            CollapsibleSection(
                                title: "Pace",
                                systemImage: "gauge.with.dots.needle.50percent",
                                tint: paceColor,
                                isExpanded: $isPaceExpanded
                            ) {
                                paceTrackerCard
                            }

                            if let savedConfirmation {
                                savedBanner(savedConfirmation)
                            }

                            TodayShiftPlanCard(
                                viewModel: plannerViewModel,
                                onOpenWaze: { plannerViewModel.openWaze() }
                            )

                            if plannerViewModel.isTodayWorkday, let plan = plannerViewModel.todayPlan {
                                ShiftEventCountdownCard(plan: plan)
                            }

                            CommutePlanCard(viewModel: plannerViewModel)
                            AlarmBuilderCard(viewModel: plannerViewModel)
                            LeavingChecklistCard(viewModel: plannerViewModel)
                            WeeklyScheduleEditorView(viewModel: plannerViewModel)
                            WazeRouteSettingsCard(viewModel: plannerViewModel)
                            ScheduleTranscriptCard(viewModel: plannerViewModel)

                            Spacer(minLength: 24)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: proxy.size.height, alignment: .top)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 44)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        startDeliveryButton
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 8)
                            .background(.ultraThinMaterial)
                    }
                }
            }
            .navigationTitle("Shift Manager")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showDeliveryCommandCenter) {
                ShiftCommandCenterView()
            }
        }
        .onChange(of: deepLinkCoordinator.openDeliveryCommandCenter) { _, shouldOpen in
            guard shouldOpen else { return }
            showDeliveryCommandCenter = true
            deepLinkCoordinator.consumeDeliveryCommandCenterRequest()
        }
        .task {
            // Drives the timing/pace text. All visible values are minute-granular,
            // so a slower tick avoids re-evaluating the whole shift tab body each second.
            while !Task.isCancelled {
                let next = Date.now
                if Int(next.timeIntervalSince(now)) >= 15 {
                    now = next
                }
                try? await Task.sleep(for: .seconds(15))
            }
        }
        .sheet(isPresented: $plannerViewModel.showChecklistSheet) {
            LeavingChecklistSheet(viewModel: plannerViewModel)
        }
        .onAppear {
            plannerViewModel.resetChecklistIfNeeded()
            Task { await plannerViewModel.refreshNotificationStatus() }
            if plannerViewModel.checklistState.isWiFiDisconnectReminderEnabled {
                wifiService.onPossibleLeaveDetected = {
                    plannerViewModel.showChecklistSheet = true
                }
                wifiService.startMonitoring()
            }
        }
        .onDisappear {
            wifiService.stopMonitoring()
        }
        .onChange(of: shiftSettings.targetHour) { _, _ in syncLiveTimingState() }
        .onChange(of: shiftSettings.targetMinute) { _, _ in syncLiveTimingState() }
        .onChange(of: shiftSettings.shiftStartHour) { _, _ in syncLiveTimingState() }
        .onChange(of: shiftSettings.shiftStartMinute) { _, _ in syncLiveTimingState() }
        .onChange(of: shiftSettings.shiftEndHour) { _, _ in syncLiveTimingState() }
        .onChange(of: shiftSettings.shiftEndMinute) { _, _ in syncLiveTimingState() }
        .onChange(of: plannerViewModel.checklistState.isWiFiDisconnectReminderEnabled) { _, enabled in
            if enabled {
                wifiService.onPossibleLeaveDetected = {
                    plannerViewModel.showChecklistSheet = true
                }
                wifiService.startMonitoring()
            } else {
                wifiService.stopMonitoring()
            }
        }
    }

    // MARK: - Shift Header

    private var shiftHeaderCard: some View {
        PremiumCard(accentColor: towerAccentColor) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(towerAccentColor)
                        .frame(width: 36, height: 36)
                        .background(towerAccentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shift")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(.white)
                        Text(now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    Spacer()
                    shiftStatusBadge
                }

                if let tower = flowVM.selectedTower {
                    HStack(spacing: 6) {
                        Text(tower.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.82))
                        Text("·")
                            .foregroundStyle(.white.opacity(0.32))
                        Text("\(flowVM.deliveryFloorNumbersForCurrentTower.count) delivery floors")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.56))
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var shiftStatusBadge: some View {
        let (label, color) = shiftStatus
        return Text(label)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.24), lineWidth: 1))
    }

    private var shiftStatus: (String, Color) {
        guard flowVM.selectedTower != nil else {
            return ("No Tower", .white.opacity(0.5))
        }
        let session = flowVM.deliverySessionState
        if session.isComplete, !session.deliveryFloors.isEmpty {
            return ("Complete", .green)
        }
        if session.isActive || session.completedCount > 0 {
            return ("In Progress", .cyan)
        }
        if !flowVM.calculationSummaries.isEmpty {
            return ("Ready", .blue)
        }
        return ("Ready", .blue)
    }

    private var headerAccessibilityLabel: String {
        let tower = flowVM.selectedTower?.name ?? "No tower selected"
        let (status, _) = shiftStatus
        return "Shift dashboard, \(now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())), \(tower), \(status)."
    }

    // MARK: - Timing Card

    private var timingCard: some View {
        PremiumCard(accentColor: .indigo.opacity(0.6)) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        isTimingExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "clock.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.indigo)
                        Text("Work Session Timing")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(paceLabel)
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(paceColor)
                            .lineLimit(1)
                        Image(systemName: isTimingExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    timingMetric("Start", value: formattedShiftStart, tint: .white)
                    timingMetric("Target", value: formattedTargetDown, tint: .cyan)
                    timingMetric("End", value: formattedShiftEnd, tint: .white)
                }

                HStack(spacing: 8) {
                    timingMetric("Until target", value: untilTargetText, tint: untilTargetColor)
                    timingMetric("Until end", value: untilEndText, tint: untilEndColor)
                }

                if isTimingExpanded {
                    Divider().background(Color.white.opacity(0.1))
                    timingEditor
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(timingAccessibilityLabel)
        .animation(.snappy(duration: 0.2), value: isTimingExpanded)
    }

    private var timingEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            timeEditRow(label: "Start", systemImage: "play.fill", selection: shiftStartBinding, tint: .white)
            timeEditRow(label: "Target down", systemImage: "flag.checkered", selection: targetDownBinding, tint: .cyan)
            timeEditRow(label: "End", systemImage: "stop.fill", selection: shiftEndBinding, tint: .white)

            HStack(spacing: 8) {
                quickTimingButton("Target +15", systemImage: "plus", tint: .cyan) {
                    adjustTarget(minutes: 15)
                }
                quickTimingButton("Use pace", systemImage: "gauge.with.dots.needle.50percent", tint: .green) {
                    setTargetFromRemainingFloors()
                }
            }
        }
    }

    private func timeEditRow(label: String, systemImage: String, selection: Binding<Date>, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(tint == .white ? 0.08 : 0.14), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.74))
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(tint == .white ? .indigo : tint)
                .colorScheme(.dark)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func quickTimingButton(_ title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func timingMetric(_ label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint.opacity(tint == .white ? 0.52 : 0.86))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(tint == .white ? 0.04 : 0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // Shift timing computations using ShiftSettings + WorkShiftWindow

    private var shiftWindow: WorkShiftWindow {
        WorkShiftWindow.containing(
            now,
            startHour: shiftSettings.shiftStartHour,
            startMinute: shiftSettings.shiftStartMinute,
            endHour: shiftSettings.shiftEndHour,
            endMinute: shiftSettings.shiftEndMinute
        )
    }

    private var targetDownDate: Date {
        shiftSettings.targetTime(for: now)
    }

    private var formattedShiftStart: String {
        shiftWindow.start.formatted(date: .omitted, time: .shortened)
    }

    private var formattedTargetDown: String {
        targetDownDate.formatted(date: .omitted, time: .shortened)
    }

    private var formattedShiftEnd: String {
        shiftWindow.end.formatted(date: .omitted, time: .shortened)
    }

    private var untilTargetText: String {
        countdownText(to: targetDownDate)
    }

    private var untilEndText: String {
        countdownText(to: shiftWindow.end)
    }

    private var untilTargetColor: Color {
        let remaining = targetDownDate.timeIntervalSince(now)
        if remaining < 0 { return .orange }
        if remaining < 1800 { return .red }
        if remaining < 3600 { return .yellow }
        return .cyan
    }

    private var untilEndColor: Color {
        let remaining = shiftWindow.end.timeIntervalSince(now)
        if remaining < 0 { return .orange }
        if remaining < 1800 { return .red }
        return .white
    }

    private func countdownText(to target: Date) -> String {
        let diff = target.timeIntervalSince(now)
        if diff <= 0 {
            let over = Int(-diff / 60) + 1
            if over >= 60 {
                return "+\(over / 60)h \(over % 60)m"
            }
            return "+\(over)m over"
        }
        let totalMinutes = Int(diff / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var timingAccessibilityLabel: String {
        "Shift timing. Start \(formattedShiftStart). Target down \(formattedTargetDown). End \(formattedShiftEnd). \(untilTargetText) until target. \(untilEndText) until end."
    }

    private var shiftStartBinding: Binding<Date> {
        Binding(
            get: { timeDate(hour: shiftSettings.shiftStartHour, minute: shiftSettings.shiftStartMinute) },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                shiftSettings.shiftStartHour = components.hour ?? shiftSettings.shiftStartHour
                shiftSettings.shiftStartMinute = components.minute ?? shiftSettings.shiftStartMinute
            }
        )
    }

    private var targetDownBinding: Binding<Date> {
        Binding(
            get: { timeDate(hour: shiftSettings.targetHour, minute: shiftSettings.targetMinute) },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                shiftSettings.targetHour = components.hour ?? shiftSettings.targetHour
                shiftSettings.targetMinute = components.minute ?? shiftSettings.targetMinute
            }
        )
    }

    private var shiftEndBinding: Binding<Date> {
        Binding(
            get: { timeDate(hour: shiftSettings.shiftEndHour, minute: shiftSettings.shiftEndMinute) },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                shiftSettings.shiftEndHour = components.hour ?? shiftSettings.shiftEndHour
                shiftSettings.shiftEndMinute = components.minute ?? shiftSettings.shiftEndMinute
            }
        )
    }

    private func timeDate(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }

    private func adjustTarget(minutes: Int) {
        let adjusted = targetDownDate.addingTimeInterval(Double(minutes) * 60)
        let components = Calendar.current.dateComponents([.hour, .minute], from: adjusted)
        shiftSettings.targetHour = components.hour ?? shiftSettings.targetHour
        shiftSettings.targetMinute = components.minute ?? shiftSettings.targetMinute
    }

    private func setTargetFromRemainingFloors() {
        let remaining = max(flowVM.remainingDeliveryFloorCount, 1)
        let workMinutes = max(remaining * 5, 15)
        let adjusted = now.addingTimeInterval(Double(workMinutes) * 60)
        let components = Calendar.current.dateComponents([.hour, .minute], from: adjusted)
        shiftSettings.targetHour = components.hour ?? shiftSettings.targetHour
        shiftSettings.targetMinute = components.minute ?? shiftSettings.targetMinute
    }

    private func syncLiveTimingState() {
        flowVM.syncWidgetState(
            shiftSettings: shiftSettings,
            completedFloors: flowVM.completedDeliveryFloorCount,
            currentItemName: flowVM.deliverySessionState.currentItemName,
            nextCarryGroupTitle: flowVM.deliverySessionState.nextCarryGroupTitle,
            isActiveSession: flowVM.deliverySessionState.isActive,
            allowsCurrentItemFallback: false
        )
    }

    // MARK: - Progress Card

    @ViewBuilder
    private var progressCard: some View {
        if flowVM.selectedTower != nil {
            let floors = flowVM.deliveryFloorNumbersForCurrentTower
            let completed = flowVM.completedDeliveryFloorCount
            let remaining = flowVM.remainingDeliveryFloorCount
            let total = floors.count
            let fraction = total > 0 ? Double(completed) / Double(total) : 0
            let next = flowVM.nextUndoneDeliveryFloor

            PremiumCard(accentColor: .green.opacity(0.6)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.green)
                        Text("Delivery Progress")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(Int((fraction * 100).rounded()))%")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.14), in: Capsule())
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.mint, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: proxy.size.width * fraction)
                        }
                    }
                    .frame(height: 8)
                    .animation(.snappy(duration: 0.3), value: fraction)

                    HStack(spacing: 8) {
                        progressMetric("Completed", "\(completed)", "floors", tint: .green)
                        progressMetric("Remaining", "\(remaining)", "floors", tint: remaining == 0 ? .green : .blue)
                        progressMetric("Next", next.map { "F\($0)" } ?? "—", remaining == 0 ? "done" : "floor", tint: .cyan)
                    }

                    if flowVM.deliveryUnitIsBundles {
                        Text("Bundle delivery mode")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.42))
                    } else {
                        Text("Piece delivery mode")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.42))
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Delivery progress. \(completed) of \(total) floors complete. \(remaining) remaining. Next floor \(next.map { floor in "\(floor)" } ?? "none").")
        } else {
            PremiumCard {
                EmptyStateView(
                    systemImage: "building.2",
                    title: "No tower selected",
                    message: "Choose a tower in Linen to start tracking this shift."
                )
            }
        }
    }

    private func progressMetric(_ label: String, _ value: String, _ detail: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint.opacity(0.86))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Floor Deliverables Card

    private var floorDeliverablesCard: some View {
        PremiumCard(accentColor: .blue.opacity(0.5)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 7) {
                    Image(systemName: "list.number")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                    Text("Floor Deliverables")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(floorDeliverablesBadge)
                        .font(.caption2.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.14), in: Capsule())
                        .overlay(Capsule().stroke(Color.blue.opacity(0.22), lineWidth: 1))
                }

                if flowVM.selectedTower == nil {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.38))
                        Text("Select a tower to see item amounts by floor.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .padding(.vertical, 4)
                } else if deliverableFloors.isEmpty || flowVM.deliveryFloorDistributions.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.38))
                        Text("Enter received items to calculate floor deliverables.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .padding(.vertical, 4)
                } else {
                    floorSelector

                    HStack(spacing: 8) {
                        parSummaryMetric("Floor", value: "F\(activeDeliverableFloor ?? 0)", detail: "selected", tint: .blue)
                        parSummaryMetric("Items", value: "\(activeFloorDeliverables.count)", detail: "deliver", tint: .cyan)
                        parSummaryMetric("Total", value: "\(activeFloorTotal)", detail: flowVM.deliveryUnitIsBundles ? "bundles" : "pieces", tint: .orange)
                    }

                    VStack(spacing: 6) {
                        ForEach(activeFloorDeliverables) { row in
                            floorDeliverableRow(row)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(floorDeliverablesAccessibilityLabel)
    }

    private var floorSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(deliverableFloors, id: \.self) { floor in
                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
                            selectedDeliverableFloor = floor
                        }
                    } label: {
                        Text("F\(floor)")
                            .font(.caption2.weight(.heavy).monospacedDigit())
                            .foregroundStyle(floor == activeDeliverableFloor ? .white : .blue)
                            .frame(minWidth: 42)
                            .frame(height: 30)
                            .background(
                                floor == activeDeliverableFloor ? Color.blue.opacity(0.72) : Color.blue.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.blue.opacity(floor == activeDeliverableFloor ? 0.5 : 0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show floor \(floor) deliverables.")
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private func floorDeliverableRow(_ row: FloorDeliveryAmount) -> some View {
        HStack(spacing: 8) {
            Image(systemName: flowVM.deliveryUnitIsBundles ? "shippingbox.fill" : "number")
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
                .frame(width: 22, height: 22)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(row.itemName)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 4)

            Text(row.amountText)
                .font(.caption2.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.14), in: Capsule())
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var deliverableFloors: [Int] {
        let floorsWithRows = Set(flowVM.deliveryFloorDistributions
            .filter { floorDeliverableAmount(for: $0) > 0 }
            .map(\.floorNumber))
        let towerFloors = flowVM.deliveryFloorNumbersForCurrentTower.filter { floorsWithRows.contains($0) }
        return towerFloors.isEmpty ? Array(floorsWithRows).sorted() : towerFloors
    }

    private func floorDeliverableAmount(for row: FloorDistributionRow) -> Int {
        flowVM.deliveryUnitIsBundles ? (row.suggestedBundles ?? row.suggestedPieces) : row.suggestedPieces
    }

    private var activeDeliverableFloor: Int? {
        if let selectedDeliverableFloor, deliverableFloors.contains(selectedDeliverableFloor) {
            return selectedDeliverableFloor
        }
        if let next = flowVM.nextUndoneDeliveryFloor, deliverableFloors.contains(next) {
            return next
        }
        return deliverableFloors.first
    }

    private var activeFloorDeliverables: [FloorDeliveryAmount] {
        guard let activeDeliverableFloor else { return [] }
        return flowVM.deliveryAmounts(onFloor: activeDeliverableFloor)
    }

    private var activeFloorTotal: Int {
        activeFloorDeliverables.reduce(0) { $0 + $1.amount }
    }

    private var floorDeliverablesBadge: String {
        activeDeliverableFloor.map { "F\($0)" } ?? "No floor"
    }

    private var floorDeliverablesAccessibilityLabel: String {
        guard let activeDeliverableFloor else {
            return "Floor deliverables. No calculated floor selected."
        }
        return "Floor \(activeDeliverableFloor) deliverables. \(activeFloorDeliverables.count) items, \(activeFloorTotal) total \(flowVM.deliveryUnitIsBundles ? "bundles" : "pieces")."
    }

    // MARK: - Tower Par Needed Card

    private var towerParNeededCard: some View {
        PremiumCard(accentColor: .cyan.opacity(0.5)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 7) {
                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.cyan)
                    Text("Tower Par Needed")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(parNeededBadge)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(parNeededColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(parNeededColor.opacity(0.14), in: Capsule())
                        .overlay(Capsule().stroke(parNeededColor.opacity(0.22), lineWidth: 1))
                }

                if flowVM.selectedTower == nil {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.38))
                        Text("Select a tower to see par pieces and bundles.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .padding(.vertical, 4)
                } else if flowVM.towerParRequirements.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.38))
                        Text("No active par items for this tower.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .padding(.vertical, 4)
                } else {
                    HStack(spacing: 8) {
                        parSummaryMetric("Items", value: "\(flowVM.towerParRequirements.count)", detail: "active", tint: .cyan)
                        parSummaryMetric("Pieces", value: "\(totalParPiecesNeeded)", detail: "to par", tint: .blue)
                        parSummaryMetric("Bundles", value: "\(totalParBundlesNeeded)", detail: "to par", tint: .orange)
                    }

                    VStack(spacing: 6) {
                        ForEach(flowVM.towerParRequirements) { row in
                            towerParRow(row)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(towerParAccessibilityLabel)
    }

    private func parSummaryMetric(_ label: String, value: String, detail: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint.opacity(0.86))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func towerParRow(_ row: TowerParRequirement) -> some View {
        HStack(spacing: 8) {
            Image(systemName: row.pieceGap < 0 ? "minus.circle.fill" : "checkmark.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(parRowColor(row))
                .frame(width: 22, height: 22)
                .background(parRowColor(row).opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(row.itemName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("\(row.parPerFloor) per floor x \(row.floorCount) floors")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(row.requiredPieces) pcs")
                    .font(.caption2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.white)
                Text("\(row.requiredBundles) bdl @ \(row.bundleSize)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.cyan.opacity(0.86))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(Color.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func parRowColor(_ row: TowerParRequirement) -> Color {
        row.pieceGap < 0 ? .red : .green
    }

    private var totalParPiecesNeeded: Int {
        flowVM.towerParRequirements.reduce(0) { $0 + $1.requiredPieces }
    }

    private var totalParBundlesNeeded: Int {
        flowVM.towerParRequirements.reduce(0) { $0 + $1.requiredBundles }
    }

    private var parNeededBadge: String {
        guard flowVM.selectedTower != nil else { return "No tower" }
        let shortCount = flowVM.towerParRequirements.filter { $0.pieceGap < 0 }.count
        return shortCount == 0 ? "Covered" : "\(shortCount) short"
    }

    private var parNeededColor: Color {
        guard flowVM.selectedTower != nil else { return .white.opacity(0.5) }
        return flowVM.towerParRequirements.contains { $0.pieceGap < 0 } ? .red : .green
    }

    private var towerParAccessibilityLabel: String {
        guard let tower = flowVM.selectedTower else {
            return "Tower par needed. No tower selected."
        }
        return "\(tower.name) par needed. \(totalParPiecesNeeded) pieces, \(totalParBundlesNeeded) bundles across \(flowVM.towerParRequirements.count) items."
    }

    // MARK: - Extras Card

    private var extrasForOtherTowersCard: some View {
        PremiumCard(accentColor: extraAvailabilityColor.opacity(0.5)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(extraAvailabilityColor)
                    Text("Extras for Other Towers")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(extraAvailabilityBadge)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(extraAvailabilityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(extraAvailabilityColor.opacity(0.14), in: Capsule())
                        .overlay(Capsule().stroke(extraAvailabilityColor.opacity(0.22), lineWidth: 1))
                }

                if flowVM.calculationSummaries.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.38))
                        Text("Enter received items in Linen to see extras.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .padding(.vertical, 4)
                } else {
                    HStack(spacing: 8) {
                        extraSummaryMetric("Items", value: "\(extraItemCount)", detail: "available", tint: extraAvailabilityColor)
                        extraSummaryMetric("Bundles", value: "\(totalExtraBundles)", detail: "left", tint: .orange)
                        extraSummaryMetric("Pieces", value: "\(totalExtraPieces)", detail: "extra", tint: .cyan)
                    }

                    VStack(spacing: 6) {
                        ForEach(extraLinenRows) { row in
                            extraLinenRow(row)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(extrasAccessibilityLabel)
    }

    private func extraSummaryMetric(_ label: String, value: String, detail: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint.opacity(0.86))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func extraLinenRow(_ row: ExtraLinenRow) -> some View {
        HStack(spacing: 8) {
            Image(systemName: row.statusIcon)
                .font(.caption.weight(.bold))
                .foregroundStyle(row.tint)
                .frame(width: 22, height: 22)
                .background(row.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(row.itemName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(row.detailText)
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 4)

            Text(row.availableText)
                .font(.caption2.weight(.heavy).monospacedDigit())
                .foregroundStyle(row.tint)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(row.tint.opacity(0.14), in: Capsule())
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(row.hasExtra ? 0.055 : 0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var extraLinenRows: [ExtraLinenRow] {
        flowVM.calculationSummaries
            .map { ExtraLinenRow(summary: $0, useBundles: flowVM.deliveryUnitIsBundles) }
            .sorted { lhs, rhs in
                if lhs.hasExtra != rhs.hasExtra { return lhs.hasExtra && !rhs.hasExtra }
                if lhs.primaryAvailable != rhs.primaryAvailable { return lhs.primaryAvailable > rhs.primaryAvailable }
                return lhs.itemName < rhs.itemName
            }
    }

    private var totalExtraBundles: Int {
        extraLinenRows.reduce(0) { $0 + $1.extraBundles }
    }

    private var totalExtraPieces: Int {
        extraLinenRows.reduce(0) { $0 + $1.extraPieces }
    }

    private var extraItemCount: Int {
        extraLinenRows.filter(\.hasExtra).count
    }

    private var extraAvailabilityBadge: String {
        guard !flowVM.calculationSummaries.isEmpty else { return "No data" }
        return extraItemCount == 0 ? "No extra" : "\(extraItemCount) items"
    }

    private var extraAvailabilityColor: Color {
        if flowVM.calculationSummaries.isEmpty { return .white.opacity(0.5) }
        return extraItemCount == 0 ? .green : .orange
    }

    private var extrasAccessibilityLabel: String {
        guard !flowVM.calculationSummaries.isEmpty else {
            return "Extras for other towers. No calculation data yet."
        }
        return "Extras for other towers. \(extraItemCount) items available. \(totalExtraBundles) bundles and \(totalExtraPieces) pieces extra."
    }

    // MARK: - Current Trip Card

    private var currentTripCard: some View {
        PremiumCard(accentColor: .mint.opacity(0.5)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Image(systemName: "shippingbox.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.mint)
                    Text("Current Trip")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    if !flowVM.currentTripItemNames.isEmpty {
                        Text("\(flowVM.currentTripItemNames.count)/2")
                            .font(.caption2.weight(.heavy).monospacedDigit())
                            .foregroundStyle(.mint)
                    }
                }

                if flowVM.currentTripItemNames.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.38))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No trip items selected yet")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                            Text("Choose items from the Floor Plan.")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.42))
                        }
                    }
                    .padding(.vertical, 6)
                } else {
                    ForEach(flowVM.currentTripItemNames, id: \.self) { itemName in
                        if let summary = flowVM.calculationSummaries.first(where: { $0.itemName == itemName }) {
                            tripItemRow(summary)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "shippingbox")
                                    .foregroundStyle(.mint.opacity(0.6))
                                Text(itemName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                    }
                }

                Text("Up to 2 item types per elevator trip.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.36))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tripAccessibilityLabel)
    }

    private func tripItemRow(_ summary: CalculationSummary) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.mint)
            VStack(alignment: .leading, spacing: 1) {
                Text(summary.itemName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("\(summary.deliverableBundles > 0 ? summary.deliverableBundles : summary.fullBundles) bdl · \(summary.receivedPieces) pcs")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.48))
            }
            Spacer(minLength: 4)
            let statusLabel = tripStatusLabel(for: summary)
            Text(statusLabel)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(tripStatusColor(statusLabel))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(tripStatusColor(statusLabel).opacity(0.14), in: Capsule())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func tripStatusLabel(for summary: CalculationSummary) -> String {
        switch summary.status {
        case .shortage: return "Short"
        case .overage: return "Over"
        case .exact: return "Exact"
        }
    }

    private func tripStatusColor(_ label: String) -> Color {
        switch label {
        case "Short": return .red
        case "Over": return .orange
        case "Exact": return .green
        default: return .white
        }
    }

    private var tripAccessibilityLabel: String {
        let items = flowVM.currentTripItemNames
        if items.isEmpty {
            return "Current trip. No items selected."
        }
        return "Current trip. \(items.joined(separator: " and ")). Up to 2 items per trip."
    }

    // MARK: - Pace Tracker Card

    private var paceTrackerCard: some View {
        PremiumCard(accentColor: paceColor.opacity(0.5)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Image(systemName: paceIcon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(paceColor)
                    Text("Pace")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(paceLabel)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(paceColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(paceColor.opacity(0.14), in: Capsule())
                        .overlay(Capsule().stroke(paceColor.opacity(0.22), lineWidth: 1))
                }

                HStack(spacing: 8) {
                    timingMetric("Remaining", value: "\(flowVM.remainingDeliveryFloorCount)", tint: .white)
                    timingMetric("Until target", value: untilTargetText, tint: untilTargetColor)
                    timingMetric("Min/floor", value: minutesPerFloorText, tint: paceColor)
                }

                HStack(spacing: 8) {
                    paceActionButton("−5m", systemImage: "minus.circle.fill", tint: .cyan) {
                        adjustTarget(minutes: -5)
                    }
                    paceActionButton("+5m", systemImage: "plus.circle.fill", tint: .cyan) {
                        adjustTarget(minutes: 5)
                    }
                    paceActionButton(
                        flowVM.nextUndoneDeliveryFloor.map { "Floor \($0) ✓" } ?? "All Done",
                        systemImage: "checkmark.circle.fill",
                        tint: flowVM.nextUndoneDeliveryFloor != nil ? .green : .white.opacity(0.4)
                    ) {
                        if let next = flowVM.nextUndoneDeliveryFloor {
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                            flowVM.markFloorCompleteAndAdvance(next)
                            syncLiveTimingState()
                        }
                    }
                    .disabled(flowVM.nextUndoneDeliveryFloor == nil)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pace tracker. \(paceLabel). \(flowVM.remainingDeliveryFloorCount) floors remaining. \(minutesPerFloorText) minutes per floor. \(untilTargetText) until target.")
    }

    private func paceActionButton(_ title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var minutesPerFloor: Double? {
        let remaining = flowVM.remainingDeliveryFloorCount
        guard remaining > 0 else { return nil }
        let secondsLeft = targetDownDate.timeIntervalSince(now)
        guard secondsLeft > 0 else { return 0 }
        return (secondsLeft / 60.0) / Double(remaining)
    }

    private var minutesPerFloorText: String {
        guard flowVM.selectedTower != nil,
              !flowVM.deliveryFloorNumbersForCurrentTower.isEmpty else {
            return "—"
        }
        guard let mpf = minutesPerFloor else {
            return "✓"
        }
        if mpf < 1 {
            return "<1m"
        }
        return "\(Int(mpf))m"
    }

    private enum PaceState {
        case notReady, complete, behind, tight, onPace
    }

    private var paceState: PaceState {
        guard flowVM.selectedTower != nil,
              !flowVM.deliveryFloorNumbersForCurrentTower.isEmpty else {
            return .notReady
        }
        if flowVM.remainingDeliveryFloorCount == 0 {
            return .complete
        }
        guard let mpf = minutesPerFloor else {
            return .behind
        }
        if mpf <= 0 { return .behind }
        if mpf >= 6 { return .onPace }
        if mpf >= 3 { return .tight }
        return .behind
    }

    private var paceLabel: String {
        switch paceState {
        case .notReady: return "Not ready"
        case .complete: return "Complete"
        case .behind: return "Behind"
        case .tight: return "Tight pace"
        case .onPace: return "On pace"
        }
    }

    private var paceColor: Color {
        switch paceState {
        case .notReady: return .white.opacity(0.5)
        case .complete: return .green
        case .behind: return .red
        case .tight: return .yellow
        case .onPace: return .cyan
        }
    }

    private var paceIcon: String {
        switch paceState {
        case .notReady: return "gauge.with.dots.needle.0percent"
        case .complete: return "checkmark.seal.fill"
        case .behind: return "exclamationmark.triangle.fill"
        case .tight: return "gauge.with.dots.needle.67percent"
        case .onPace: return "gauge.with.dots.needle.33percent"
        }
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        @Bindable var vm = flowVM
        return PremiumCard(accentColor: .orange.opacity(0.4)) {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        isNotesExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "note.text")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                        Text("Notes")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white)
                        Spacer()
                        if !isNotesExpanded, !flowVM.notes.isEmpty {
                            Text(flowVM.notes.prefix(40) + (flowVM.notes.count > 40 ? "…" : ""))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.52))
                                .lineLimit(1)
                        }
                        Image(systemName: isNotesExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(flowVM.notes.isEmpty ? "Notes. No notes yet." : "Notes. \(flowVM.notes.prefix(60)).")
                .accessibilityHint(isNotesExpanded ? "Double tap to collapse." : "Double tap to expand and edit.")

                if isNotesExpanded {
                    if flowVM.notes.isEmpty, !isNotesExpanded {
                        Text("No notes yet")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    TextEditor(text: $vm.notes)
                        .scrollContentBackground(.hidden)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.86))
                        .frame(minHeight: 80, maxHeight: 180)
                        .padding(8)
                        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.orange.opacity(0.18), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.snappy(duration: 0.2), value: isNotesExpanded)
    }

    // MARK: - End Shift Summary Card

    private var endShiftSummaryCard: some View {
        PremiumCard(accentColor: summaryAccentColor.opacity(0.5)) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        isSummaryExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: summaryIcon)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(summaryAccentColor)
                        Text("Session Summary")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white)
                        Spacer()
                        if !isSummaryExpanded {
                            Text(summaryOneLiner)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.52))
                                .lineLimit(1)
                        }
                        Image(systemName: isSummaryExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(isSummaryExpanded ? "Double tap to collapse." : "Double tap to expand.")

                if isSummaryExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        summaryRow("Tower", value: flowVM.selectedTower?.name ?? "—")
                        summaryRow("Floors", value: "\(flowVM.completedDeliveryFloorCount)/\(flowVM.deliveryFloorNumbersForCurrentTower.count)")
                        summaryRow("Remaining", value: "\(flowVM.remainingDeliveryFloorCount) floors")
                        summaryRow("Target down", value: formattedTargetDown)
                        summaryRow("Shift end", value: formattedShiftEnd)
                        if !flowVM.currentTripItemNames.isEmpty {
                            summaryRow("Trip items", value: flowVM.currentTripItemNames.joined(separator: ", "))
                        }
                        if !flowVM.notes.isEmpty {
                            summaryRow("Notes", value: String(flowVM.notes.prefix(60)) + (flowVM.notes.count > 60 ? "…" : ""))
                        }

                        if flowVM.remainingDeliveryFloorCount == 0,
                           !flowVM.deliveryFloorNumbersForCurrentTower.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                Text("Route complete")
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(.green)
                            }
                            .padding(.top, 4)
                        }

                        // Save log shortcut
                        if canSaveLog {
                            Button(action: saveLog) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down.fill")
                                        .font(.caption.weight(.bold))
                                    Text("Save Daily Log")
                                        .font(.caption.weight(.bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color.green.opacity(0.22), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.green.opacity(0.36), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Save today's daily log.")
                            .padding(.top, 4)
                        } else if flowVM.selectedTower != nil, flowVM.calculationSummaries.isEmpty {
                            Text("Enter received items in Linen to save a log.")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.42))
                                .padding(.top, 2)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.snappy(duration: 0.2), value: isSummaryExpanded)
    }

    private func summaryRow(_ label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.52))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Spacer()
        }
    }

    private var summaryAccentColor: Color {
        if flowVM.selectedTower == nil { return .white.opacity(0.3) }
        let remaining = flowVM.remainingDeliveryFloorCount
        let total = flowVM.deliveryFloorNumbersForCurrentTower.count
        if total > 0, remaining == 0 { return .green }
        return .blue
    }

    private var summaryIcon: String {
        let remaining = flowVM.remainingDeliveryFloorCount
        let total = flowVM.deliveryFloorNumbersForCurrentTower.count
        if total > 0, remaining == 0 { return "checkmark.seal.fill" }
        return "doc.text.fill"
    }

    private var summaryOneLiner: String {
        guard flowVM.selectedTower != nil else { return "No tower" }
        let completed = flowVM.completedDeliveryFloorCount
        let total = flowVM.deliveryFloorNumbersForCurrentTower.count
        if total > 0, flowVM.remainingDeliveryFloorCount == 0 {
            return "Route complete"
        }
        return "\(completed)/\(total) floors"
    }

    // MARK: - Save Log

    private var canSaveLog: Bool {
        flowVM.selectedTower != nil
        && !flowVM.receivingEntries.isEmpty
        && !flowVM.calculationSummaries.isEmpty
    }

    private func saveLog() {
        switch DailyLogSaveService.save(viewModel: flowVM, context: modelContext) {
        case .success:
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            savedConfirmation = "Daily log saved."
            savedAt = .now
        case .failure(let err):
            savedConfirmation = err.errorDescription ?? "Save failed."
        }
    }

    private func savedBanner(_ message: String) -> some View {
        PremiumCard(accentColor: .green) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    if let savedAt {
                        Text(savedAt.formatted(date: .omitted, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    // MARK: - Delivery Command Button

    private var startDeliveryButton: some View {
        let accent = towerAccentColor
        let enabled = flowVM.selectedTower != nil
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

    // MARK: - Helpers

    private var towerAccentColor: Color {
        guard let tower = flowVM.selectedTower,
              let hex = tower.identityColorHex,
              let color = Color(hex: hex) else {
            return .blue
        }
        return color
    }
}

private struct ExtraLinenRow: Identifiable {
    let id: UUID
    let itemName: String
    let extraBundles: Int
    let loosePieces: Int
    let extraPieces: Int
    let shortagePieces: Int
    let shortageBundles: Int
    let bundleSize: Int
    let useBundles: Bool

    init(summary: CalculationSummary, useBundles: Bool) {
        id = summary.id
        itemName = summary.itemName
        extraBundles = max(0, summary.leftoverBundles)
        loosePieces = max(0, summary.loosePieces)
        extraPieces = max(0, summary.differencePieces)
        shortagePieces = max(0, -summary.differencePieces)
        shortageBundles = max(0, summary.shortageBundles)
        bundleSize = max(1, summary.bundleSize)
        self.useBundles = useBundles
    }

    var hasExtra: Bool {
        primaryAvailable > 0 || availableLoosePieces > 0
    }

    var primaryAvailable: Int {
        useBundles ? extraBundles : extraPieces
    }

    var availableLoosePieces: Int {
        guard useBundles, extraPieces > 0 else { return 0 }
        return max(0, extraPieces - extraBundles * bundleSize)
    }

    var availableText: String {
        if useBundles {
            if extraBundles > 0 { return "\(extraBundles) bdl" }
            if availableLoosePieces > 0 { return "\(availableLoosePieces) loose" }
            if shortageBundles > 0 { return "short \(shortageBundles) bdl" }
            return "0"
        }

        if extraPieces > 0 { return "+\(extraPieces) pcs" }
        if shortagePieces > 0 { return "short \(shortagePieces) pcs" }
        return "0"
    }

    var detailText: String {
        if useBundles {
            let looseText = availableLoosePieces > 0 ? " · \(availableLoosePieces) loose pcs" : ""
            if extraBundles > 0 {
                return "Available for another tower\(looseText)"
            }
            if availableLoosePieces > 0 {
                return "Loose pieces available"
            }
            if shortageBundles > 0 {
                return "\(shortageBundles) bundles short for this tower (\(shortagePieces) pcs)"
            }
            return "No extra after this tower"
        }

        if extraPieces > 0 {
            return "Available after this tower"
        }
        if shortagePieces > 0 {
            return "\(shortagePieces) pcs short for this tower"
        }
        return "No extra after this tower"
    }

    var statusIcon: String {
        if hasExtra { return "shippingbox.and.arrow.backward.fill" }
        if shortagePieces > 0 { return "exclamationmark.triangle.fill" }
        return "checkmark.circle.fill"
    }

    var tint: Color {
        if hasExtra { return .orange }
        if shortagePieces > 0 { return .red }
        return .green
    }
}
