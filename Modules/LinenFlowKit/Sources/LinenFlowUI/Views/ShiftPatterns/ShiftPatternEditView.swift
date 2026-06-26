import SwiftUI
import SwiftData
import LinenFlowCore
import LinenFlowEngine

public struct ShiftPatternEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable public var orchestrator: ShiftOrchestrator

    @State private var name: String
    @State private var selectedDays: Set<Weekday>
    @State private var clockInDate: Date
    @State private var shiftDurationMinutes: Int
    @State private var isActive: Bool
    @State private var workLocation: SavedLocation?
    @State private var showWorkLocationPicker = false

    private let existingID: UUID?
    private let isEditing: Bool

    public init(pattern: ShiftPattern? = nil, orchestrator: ShiftOrchestrator) {
        self.orchestrator = orchestrator
        if let pattern {
            _name = State(initialValue: pattern.name)
            _selectedDays = State(initialValue: pattern.daysOfWeek)
            var components = DateComponents()
            components.hour = pattern.clockInHour
            components.minute = pattern.clockInMinute
            _clockInDate = State(initialValue: Calendar.current.date(from: components) ?? .now)
            _shiftDurationMinutes = State(initialValue: pattern.shiftDurationMinutes)
            _isActive = State(initialValue: pattern.isActive)
            _workLocation = State(initialValue: pattern.workLocation)
            existingID = pattern.id
            isEditing = true
        } else {
            _name = State(initialValue: "Night Shift")
            _selectedDays = State(initialValue: [])
            _clockInDate = State(initialValue: Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: .now) ?? .now)
            _shiftDurationMinutes = State(initialValue: 480)
            _isActive = State(initialValue: true)
            _workLocation = State(initialValue: nil)
            existingID = nil
            isEditing = false
        }
    }

    public var body: some View {
        Form {
            Section("Pattern") {
                TextField("Name", text: $name)
                Toggle("Active", isOn: $isActive)
            }
            .listRowBackground(HimmerFlowColors.surface)

            Section("Days") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        dayChip(day)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(HimmerFlowColors.surface)

            Section("Clock in") {
                DatePicker("Time", selection: $clockInDate, displayedComponents: .hourAndMinute)
            }
            .listRowBackground(HimmerFlowColors.surface)

            Section("Shift length") {
                DurationPickerView(
                    title: "Duration",
                    minutes: $shiftDurationMinutes,
                    range: 60...720,
                    step: 15
                )
            }
            .listRowBackground(HimmerFlowColors.surface)

            Section("Work location") {
                if let workLocation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workLocation.label)
                        Text("Radius \(Int(workLocation.radiusMeters)) m")
                            .font(.caption)
                            .foregroundStyle(HimmerFlowColors.mutedText)
                    }
                } else {
                    Text("Optional — enables arrival detection")
                        .font(.caption)
                        .foregroundStyle(HimmerFlowColors.mutedText)
                }
                Button(workLocation == nil ? "Add work location" : "Change work location") {
                    showWorkLocationPicker = true
                }
                if workLocation != nil {
                    Button("Remove work location", role: .destructive) {
                        workLocation = nil
                    }
                }
            }
            .listRowBackground(HimmerFlowColors.surface)
        }
        .scrollContentBackground(.hidden)
        .background(HimmerFlowColors.background)
        .navigationTitle(isEditing ? "Edit Pattern" : "New Pattern")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedDays.isEmpty)
            }
        }
        .sheet(isPresented: $showWorkLocationPicker) {
            NavigationStack {
                LocationPickerView(
                    title: "Work",
                    locationType: .work,
                    existing: workLocation
                ) { saved in
                    workLocation = saved
                }
            }
        }
    }

    private func dayChip(_ day: Weekday) -> some View {
        let isSelected = selectedDays.contains(day)
        return Button {
            if isSelected {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
        } label: {
            Text(day.shortName)
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? .white : HimmerFlowColors.secondaryText)
                .background(
                    isSelected ? HimmerFlowColors.ctaFill : HimmerFlowColors.surface,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.shortName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: clockInDate)
        if let existingID,
           let pattern = try? modelContext.fetch(FetchDescriptor<ShiftPattern>()).first(where: { $0.id == existingID }) {
            pattern.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            pattern.daysOfWeek = selectedDays
            pattern.clockInTime = components
            pattern.shiftDurationMinutes = shiftDurationMinutes
            pattern.isActive = isActive
            pattern.workLocation = workLocation
        } else {
            let pattern = ShiftPattern(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                daysOfWeek: selectedDays,
                clockInTime: components,
                shiftDurationMinutes: shiftDurationMinutes,
                workLocation: workLocation,
                isActive: isActive
            )
            modelContext.insert(pattern)
        }

        try? modelContext.save()
        Task {
            await orchestrator.reconcile(trigger: .settingsChanged)
            dismiss()
        }
    }
}
