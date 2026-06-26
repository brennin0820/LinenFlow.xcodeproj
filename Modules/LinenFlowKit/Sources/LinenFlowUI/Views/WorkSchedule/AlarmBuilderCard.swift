import SwiftUI
import UserNotifications
import LinenFlowCore
import LinenFlowEngine

public struct AlarmBuilderCard: View {
    @Bindable public var viewModel: SmartShiftAlarmPlannerViewModel

    public var body: some View {
        PremiumCard(accentColor: alarmAccentColor) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "alarm.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(alarmAccentColor.opacity(0.75), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alarm Builder")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(permissionSubtitle)
                            .font(.caption)
                            .foregroundStyle(permissionSubtitleColor.opacity(0.78))
                    }
                    Spacer()
                    // Master toggle
                    Toggle("", isOn: $viewModel.alarmPlan.isEnabled)
                        .labelsHidden()
                        .tint(.orange)
                }

                // Permission warning
                if viewModel.notificationAuthStatus == .denied {
                    permissionWarningBanner
                        .padding(.top, 12)
                }

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                // Alarm toggles
                let plan = viewModel.heroDisplayPlan
                VStack(spacing: 2) {
                    alarmRow(
                        "Get Ready",
                        icon: "clock.fill",
                        enabled: $viewModel.alarmPlan.getReadyEnabled,
                        time: plan?.startGettingReadyTime,
                        tint: .cyan
                    )
                    alarmRow(
                        "Leave Soon",
                        icon: "bell.fill",
                        enabled: $viewModel.alarmPlan.leaveSoonEnabled,
                        time: plan?.leaveSoonTime,
                        tint: .yellow
                    )
                    alarmRow(
                        "Leaving Checklist",
                        icon: "checklist",
                        enabled: $viewModel.alarmPlan.checklistEnabled,
                        time: plan?.checklistReminderTime,
                        tint: .green
                    )
                    alarmRow(
                        "Walk to Car",
                        icon: "figure.walk",
                        enabled: $viewModel.alarmPlan.walkToCarEnabled,
                        time: plan?.walkToCarTime,
                        tint: .green
                    )
                    alarmRow(
                        "Start Driving",
                        icon: "car.fill",
                        enabled: $viewModel.alarmPlan.startDrivingEnabled,
                        time: plan?.startDrivingTime,
                        tint: .orange
                    )
                    alarmRow(
                        "Shift Soon",
                        icon: "moon.stars.fill",
                        enabled: $viewModel.alarmPlan.shiftSoonEnabled,
                        time: plan?.shiftSoonTime,
                        tint: .purple
                    )
                }

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                // Action buttons
                HStack(spacing: 10) {
                    Button {
                        Task { await viewModel.cancelAlarms() }
                    } label: {
                        Label("Cancel Alarms", systemImage: "xmark.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.white.opacity(0.78))
                            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await viewModel.scheduleAlarms() }
                    } label: {
                        Label("Schedule Alarms", systemImage: "alarm.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.white)
                            .background(
                                viewModel.alarmPlan.isEnabled
                                    ? LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.05)], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.alarmPlan.isEnabled || viewModel.notificationAuthStatus == .denied)
                }

                if viewModel.isAlarmsScheduled {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Alarms scheduled for this shift")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .onChange(of: viewModel.alarmPlan.isEnabled) { _, _ in viewModel.save() }
        .onChange(of: viewModel.alarmPlan.getReadyEnabled) { _, _ in viewModel.save() }
        .onChange(of: viewModel.alarmPlan.leaveSoonEnabled) { _, _ in viewModel.save() }
        .onChange(of: viewModel.alarmPlan.checklistEnabled) { _, _ in viewModel.save() }
        .onChange(of: viewModel.alarmPlan.walkToCarEnabled) { _, _ in viewModel.save() }
        .onChange(of: viewModel.alarmPlan.startDrivingEnabled) { _, _ in viewModel.save() }
        .onChange(of: viewModel.alarmPlan.shiftSoonEnabled) { _, _ in viewModel.save() }
        .task { await viewModel.refreshNotificationStatus() }
    }

    // MARK: - Helpers

    private var alarmAccentColor: Color {
        viewModel.alarmPlan.isEnabled ? .orange : .gray
    }

    private var permissionSubtitle: String {
        switch viewModel.notificationAuthStatus {
        case .authorized, .provisional: return "Notifications enabled"
        case .denied: return "Notifications disabled"
        case .notDetermined: return "Permission not requested"
        default: return "Unknown status"
        }
    }

    private var permissionSubtitleColor: Color {
        switch viewModel.notificationAuthStatus {
        case .authorized, .provisional: return .green
        case .denied: return .red
        default: return .yellow
        }
    }

    private var permissionWarningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text("Notifications are disabled. Enable them in iOS Settings to receive shift alarms.")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(10)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.orange.opacity(0.22), lineWidth: 1))
    }

    private func alarmRow(_ label: String, icon: String, enabled: Binding<Bool>, time: Date?, tint: Color) -> some View {
        TimelineView(.everyMinute) { context in
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(enabled.wrappedValue ? tint : .white.opacity(0.25))
                    .frame(width: 22, height: 22)
                    .background((enabled.wrappedValue ? tint : Color.white).opacity(0.08), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(enabled.wrappedValue ? .white : .white.opacity(0.45))
                    if let time, enabled.wrappedValue {
                        let remaining = time.timeIntervalSince(context.date)
                        if remaining > 0 {
                            Text("in \(WorkdayPlan.countdownString(from: context.date, to: time))")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(tint.opacity(0.72))
                                .contentTransition(.numericText())
                        } else if remaining > -3600 {
                            Text("passed")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.38))
                        }
                    }
                }

                Spacer()

                if let time {
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(enabled.wrappedValue ? tint : .white.opacity(0.28))
                }

                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .tint(tint)
                    .disabled(!viewModel.alarmPlan.isEnabled)
            }
            .padding(.vertical, 8)
            .opacity(viewModel.alarmPlan.isEnabled ? 1 : 0.5)
        }
    }
}
