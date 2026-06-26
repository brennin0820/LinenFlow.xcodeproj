import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct WeeklyScheduleEditorView: View {
    @Bindable public var viewModel: SmartShiftAlarmPlannerViewModel

    public var body: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "Weekly Schedule", subtitle: "Set your work days and tower assignments")
                .padding(.horizontal, 2)

            ForEach(Array(viewModel.schedule.indices), id: \.self) { index in
                WorkScheduleDayCard(
                    day: $viewModel.schedule[index],
                    onChanged: { viewModel.save() }
                )
            }
        }
    }
}

// MARK: - Day Card

public struct WorkScheduleDayCard: View {
    @Binding public var day: WorkScheduleDay
    public let onChanged: () -> Void
    @State private var expanded = false

    private static let towerOptions: [String] = [
        "Unassigned",
        "Lagoon", "Tapa", "Rainbow", "Ali'i", "Diamond",
        "Grand Waikikian", "Grand Islander", "Kalia",
        "Other"
    ]

    public var body: some View {
        PremiumCard(accentColor: day.isWorkday ? towerColor : nil) {
            VStack(spacing: 0) {
                // Top row: day name + toggle
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.weekdayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if day.isWorkday {
                            Text(day.shiftTimeLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                        } else {
                            Text("Off")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.38))
                        }
                    }

                    Spacer()

                    if day.isWorkday {
                        towerBadge
                    }

                    Toggle("", isOn: $day.isWorkday)
                        .labelsHidden()
                        .tint(towerColor)
                        .onChange(of: day.isWorkday) { _, _ in onChanged() }
                }

                if day.isWorkday {
                    Button {
                        withAnimation(.snappy(duration: 0.24)) { expanded.toggle() }
                    } label: {
                        HStack {
                            Text(expanded ? "Less" : "Edit Details")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.55))
                            Spacer()
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.38))
                        }
                        .padding(.top, 10)
                    }
                    .buttonStyle(.plain)

                    if expanded {
                        Divider().background(Color.white.opacity(0.08)).padding(.vertical, 10)
                        detailControls
                    }
                }
            }
        }
        .opacity(day.isWorkday ? 1 : 0.65)
    }

    @ViewBuilder
    private var detailControls: some View {
        VStack(spacing: 12) {
            // Shift time pickers
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start".uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(0.6)
                    DatePicker("", selection: shiftStartBinding, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(towerColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("End".uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(0.6)
                    DatePicker("", selection: shiftEndBinding, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(towerColor)
                }
                Spacer()
            }

            if day.isOvernightShift {
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.caption2)
                        .foregroundStyle(.indigo)
                    Text("Overnight shift — ends next day")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
            }

            // Tower assignment
            VStack(alignment: .leading, spacing: 6) {
                Text("Tower".uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(0.6)

                Picker("Tower", selection: $day.assignedTowerName) {
                    ForEach(Self.towerOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(towerColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onChange(of: day.assignedTowerName) { _, _ in onChanged() }

                if day.assignedTowerName == "Other" {
                    TextField("Custom tower name", text: customTowerNameBinding)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .tint(towerColor)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }

    // MARK: - Bindings

    private var shiftStartBinding: Binding<Date> {
        Binding(
            get: { timeDate(hour: day.shiftStartHour, minute: day.shiftStartMinute) },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                day.shiftStartHour = comps.hour ?? 23
                day.shiftStartMinute = comps.minute ?? 0
                onChanged()
            }
        )
    }

    private var shiftEndBinding: Binding<Date> {
        Binding(
            get: { timeDate(hour: day.shiftEndHour, minute: day.shiftEndMinute) },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                day.shiftEndHour = comps.hour ?? 7
                day.shiftEndMinute = comps.minute ?? 0
                onChanged()
            }
        )
    }

    private var customTowerNameBinding: Binding<String> {
        Binding(
            get: { day.customTowerName ?? "" },
            set: { day.customTowerName = $0.isEmpty ? nil : $0; onChanged() }
        )
    }

    private func timeDate(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return Calendar.current.date(from: comps) ?? .now
    }

    // MARK: - Tower color + badge

    private var towerColor: Color {
        WorkScheduleTowerColor.color(for: day.assignedTowerName)
    }

    @ViewBuilder
    private var towerBadge: some View {
        if day.assignedTowerName == "Unassigned" {
            Label("Unassigned", systemImage: "exclamationmark.triangle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12), in: Capsule())
        } else {
            Text(day.assignedTowerName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(towerColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(towerColor.opacity(0.14), in: Capsule())
                .overlay(Capsule().stroke(towerColor.opacity(0.22), lineWidth: 1))
        }
    }
}
