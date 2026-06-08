import SwiftUI
import SwiftData

struct ShiftPatternListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShiftPattern.name) private var patterns: [ShiftPattern]

    @Bindable var orchestrator: ShiftOrchestrator
    @State private var editingPattern: ShiftPattern?
    @State private var showCreate = false

    var body: some View {
        List {
            if patterns.isEmpty {
                ContentUnavailableView(
                    "No shift patterns",
                    systemImage: "calendar.badge.plus",
                    description: Text("Add a repeating weekly pattern to build your timeline.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(patterns, id: \.id) { pattern in
                    Button {
                        editingPattern = pattern
                    } label: {
                        ShiftPatternRow(pattern: pattern)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(HimmerFlowColors.surface)
                }
                .onDelete(perform: deletePatterns)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HimmerFlowColors.background)
        .navigationTitle("Shift Patterns")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add shift pattern")
            }
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                ShiftPatternEditView(orchestrator: orchestrator)
            }
        }
        .sheet(isPresented: Binding(
            get: { editingPattern != nil },
            set: { if !$0 { editingPattern = nil } }
        )) {
            if let editingPattern {
                NavigationStack {
                    ShiftPatternEditView(pattern: editingPattern, orchestrator: orchestrator)
                }
            }
        }
    }

    private func deletePatterns(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(patterns[index])
        }
        try? modelContext.save()
        Task { await orchestrator.reconcile(trigger: .settingsChanged) }
    }
}

private struct ShiftPatternRow: View {
    let pattern: ShiftPattern

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(pattern.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(HimmerFlowColors.heroText)
                Spacer()
                if !pattern.isActive {
                    Text("Inactive")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(HimmerFlowColors.mutedText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(HimmerFlowColors.border, in: Capsule())
                }
            }

            Text(daysLabel)
                .font(.caption)
                .foregroundStyle(HimmerFlowColors.mutedText)

            HStack(spacing: 12) {
                Label(clockInLabel, systemImage: "clock.fill")
                Label(durationLabel, systemImage: "hourglass")
                if pattern.workLocation != nil {
                    Label("Work set", systemImage: "mappin.and.ellipse")
                }
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(HimmerFlowColors.secondaryText)
        }
        .padding(.vertical, 4)
    }

    private var daysLabel: String {
        let days = pattern.daysOfWeek.sorted { $0.rawValue < $1.rawValue }.map(\.shortName)
        return days.isEmpty ? "No days selected" : days.joined(separator: ", ")
    }

    private var clockInLabel: String {
        let hour = pattern.clockInHour
        let minute = pattern.clockInMinute
        var components = DateComponents(hour: hour, minute: minute)
        let date = Calendar.current.date(from: components) ?? .now
        return HimmerFlowDateFormatting.timeString(date)
    }

    private var durationLabel: String {
        let hours = pattern.shiftDurationMinutes / 60
        let minutes = pattern.shiftDurationMinutes % 60
        if minutes == 0 { return "\(hours)h shift" }
        return "\(hours)h \(minutes)m"
    }
}
