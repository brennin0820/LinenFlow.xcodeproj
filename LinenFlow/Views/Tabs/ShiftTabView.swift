import SwiftUI

struct ShiftTabView: View {
    @Environment(ShiftSettings.self) private var shiftSettings

    @State private var plannerViewModel = SmartShiftAlarmPlannerViewModel()
    @State private var wifiService = WiFiLeaveDetectionService()
    @State private var now = Date.now
    @State private var isTimingExpanded = false

    @State private var isTodayPlanExpanded = true
    @State private var isCountdownExpanded = true
    @State private var isCommuteExpanded = false
    @State private var isAlarmsExpanded = false
    @State private var isLeavingChecklistExpanded = false
    @State private var isWeeklyScheduleExpanded = false
    @State private var isWazeExpanded = false
    @State private var isTranscriptExpanded = false

    var body: some View {
        NavigationStack {
            AppBackground {
                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: 14) {
                            shiftHeaderCard
                            timingCard

                            collapsibleSection(
                                "Today's Shift Plan",
                                systemImage: "calendar.badge.clock",
                                tint: .blue,
                                isExpanded: $isTodayPlanExpanded
                            ) {
                                TodayShiftPlanCard(
                                    viewModel: plannerViewModel,
                                    onOpenWaze: { plannerViewModel.openWaze() }
                                )
                            }

                            if plannerViewModel.isTodayWorkday, let plan = plannerViewModel.todayPlan {
                                collapsibleSection(
                                    "Shift Countdown",
                                    systemImage: "timer",
                                    tint: .orange,
                                    isExpanded: $isCountdownExpanded
                                ) {
                                    ShiftEventCountdownCard(plan: plan)
                                }
                            }

                            collapsibleSection(
                                "Commute",
                                systemImage: "car.fill",
                                tint: .green,
                                isExpanded: $isCommuteExpanded
                            ) {
                                CommutePlanCard(viewModel: plannerViewModel)
                            }

                            collapsibleSection(
                                "Alarms",
                                systemImage: "alarm.fill",
                                tint: .red,
                                isExpanded: $isAlarmsExpanded
                            ) {
                                AlarmBuilderCard(viewModel: plannerViewModel)
                            }

                            collapsibleSection(
                                "Leaving Checklist",
                                systemImage: "checklist",
                                tint: .mint,
                                isExpanded: $isLeavingChecklistExpanded
                            ) {
                                LeavingChecklistCard(viewModel: plannerViewModel)
                            }

                            collapsibleSection(
                                "Weekly Schedule",
                                systemImage: "calendar",
                                tint: .indigo,
                                isExpanded: $isWeeklyScheduleExpanded
                            ) {
                                WeeklyScheduleEditorView(viewModel: plannerViewModel)
                            }

                            collapsibleSection(
                                "Route Settings",
                                systemImage: "map.fill",
                                tint: .cyan,
                                isExpanded: $isWazeExpanded
                            ) {
                                WazeRouteSettingsCard(viewModel: plannerViewModel)
                            }

                            collapsibleSection(
                                "Schedule Notes",
                                systemImage: "note.text",
                                tint: .yellow,
                                isExpanded: $isTranscriptExpanded
                            ) {
                                ScheduleTranscriptCard(viewModel: plannerViewModel)
                            }

                            Spacer(minLength: 24)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: proxy.size.height, alignment: .top)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 44)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationTitle("Shift")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
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

    // MARK: - Header

    private var shiftHeaderCard: some View {
        PremiumCard(accentColor: headerAccentColor) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: plannerViewModel.isTodayWorkday ? "moon.stars.fill" : "sun.max.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(headerAccentColor)
                        .frame(width: 36, height: 36)
                        .background(headerAccentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shift")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(.white)
                        Text(now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    Spacer()
                    scheduleStatusBadge
                }

                if let plan = plannerViewModel.heroDisplayPlan {
                    HStack(spacing: 6) {
                        Text(plan.assignedTowerName == "Unassigned" ? "No tower assigned" : plan.assignedTowerName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.82))
                        Text("·")
                            .foregroundStyle(.white.opacity(0.32))
                        Text(
                            plan.shiftStartDateTime.formatted(date: .omitted, time: .shortened)
                                + " – "
                                + plan.shiftEndDateTime.formatted(date: .omitted, time: .shortened)
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    }
                } else {
                    Text("Set your weekly schedule to see upcoming shifts.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.56))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var scheduleStatusBadge: some View {
        let (label, color) = scheduleStatus
        return Text(label)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.24), lineWidth: 1))
    }

    private var scheduleStatus: (String, Color) {
        if plannerViewModel.isTodayWorkday {
            return ("Work Night", .cyan)
        }
        if plannerViewModel.heroDisplayPlan != nil {
            return ("Off Today", .white.opacity(0.55))
        }
        return ("No Schedule", .white.opacity(0.45))
    }

    private var headerAccentColor: Color {
        if plannerViewModel.isTodayWorkday {
            return .cyan
        }
        return .indigo
    }

    private var headerAccessibilityLabel: String {
        let (status, _) = scheduleStatus
        let date = now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        if let plan = plannerViewModel.heroDisplayPlan {
            return "Shift dashboard, \(date), \(status), \(plan.assignedTowerName)."
        }
        return "Shift dashboard, \(date), \(status)."
    }

    // MARK: - Work Session Timing

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

            quickTimingButton("Target +15", systemImage: "plus", tint: .cyan) {
                adjustTarget(minutes: 15)
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

    // MARK: - Collapsible Sections

    @ViewBuilder
    private func collapsibleSection<Content: View>(
        _ title: String,
        systemImage: String,
        tint: Color,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.snappy(duration: 0.22)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                        .frame(width: 28, height: 28)
                        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(0.18), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityHint(isExpanded.wrappedValue ? "Double tap to collapse." : "Double tap to expand.")

            if isExpanded.wrappedValue {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.snappy(duration: 0.22), value: isExpanded.wrappedValue)
    }
}
