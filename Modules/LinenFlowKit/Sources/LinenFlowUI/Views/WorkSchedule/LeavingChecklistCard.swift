import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct LeavingChecklistCard: View {
    @Bindable public var viewModel: SmartShiftAlarmPlannerViewModel
    @State private var showSheet = false
    @State private var showAddItem = false
    @State private var newItemTitle = ""

    public var body: some View {
        PremiumCard(accentColor: .green) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "checklist")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.green.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Leaving Checklist")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Before you walk to the car")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Button { showSheet = true } label: {
                        Text("View All")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                // Progress bar
                let progress = viewModel.checklistProgress
                if progress.total > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(progress.checked)/\(progress.total) checked")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                            Spacer()
                            if progress.checked > 0 {
                                Button {
                                    withAnimation(.snappy(duration: 0.22)) {
                                        viewModel.resetChecklist()
                                    }
                                } label: {
                                    Label("Reset", systemImage: "arrow.counterclockwise")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.52))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.07), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        ProgressView(value: Double(progress.checked), total: Double(progress.total))
                            .progressViewStyle(.linear)
                            .tint(progress.checked == progress.total ? .green : .green.opacity(0.72))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                            .background(Color.white.opacity(0.10), in: Capsule())
                            .clipShape(Capsule())
                            .animation(.spring(response: 0.45, dampingFraction: 0.88), value: progress.checked)
                    }
                    .padding(.bottom, 10)
                }

                // Checklist items (show up to 4)
                let displayed = viewModel.activeChecklistItems.prefix(4)
                if displayed.isEmpty {
                    EmptyStateView(
                        systemImage: "checklist",
                        title: "No active items",
                        message: "Add items to your checklist below."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(displayed)) { item in
                            ChecklistItemRow(
                                item: item,
                                isChecked: viewModel.isChecked(item)
                            ) {
                                withAnimation(.snappy(duration: 0.18)) {
                                    viewModel.toggleChecked(item)
                                }
                            }
                            if item.id != displayed.last?.id {
                                Divider().background(Color.white.opacity(0.06))
                            }
                        }
                    }

                    if viewModel.activeChecklistItems.count > 4 {
                        Button { showSheet = true } label: {
                            Text("View all \(viewModel.activeChecklistItems.count) items")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                }

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                // Reminder time row
                let plan = viewModel.heroDisplayPlan
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                        .frame(width: 22, height: 22)
                        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("Reminder")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                    Spacer()
                    if let planTime = plan?.checklistReminderTime {
                        Text(planTime.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(.green)
                    }
                    Toggle("", isOn: $viewModel.checklistState.isChecklistReminderEnabled)
                        .labelsHidden()
                        .tint(.green)
                }

                // Wi-Fi helper (optional)
                wifiHelperSection

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                // Add item
                if showAddItem {
                    HStack(spacing: 8) {
                        TextField("New item name", text: $newItemTitle)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .tint(.green)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .submitLabel(.done)
                            .onSubmit { addItem() }
                        Button("Add") { addItem() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                        Button("Cancel") {
                            newItemTitle = ""
                            showAddItem = false
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    }
                } else {
                    Button {
                        withAnimation(.snappy(duration: 0.22)) { showAddItem = true }
                    } label: {
                        Label("Add Item", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            LeavingChecklistSheet(viewModel: viewModel)
        }
        .onChange(of: viewModel.checklistState.isChecklistReminderEnabled) { _, _ in viewModel.save() }
    }

    private var wifiHelperSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().background(Color.white.opacity(0.06)).padding(.vertical, 6)
            HStack(spacing: 8) {
                Image(systemName: "wifi")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.blue)
                    .frame(width: 22, height: 22)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text("Show checklist when home Wi-Fi disconnects")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Toggle("", isOn: $viewModel.checklistState.isWiFiDisconnectReminderEnabled)
                    .labelsHidden()
                    .tint(.blue)
            }

            if viewModel.checklistState.isWiFiDisconnectReminderEnabled {
                TextField("Home Wi-Fi name (optional)", text: wifiNameBinding)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .tint(.blue)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("Wi-Fi detection works only when available. Time-based alarms are the reliable reminder.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onChange(of: viewModel.checklistState.isWiFiDisconnectReminderEnabled) { _, _ in viewModel.save() }
        .onChange(of: viewModel.checklistState.homeWiFiName) { _, _ in viewModel.save() }
    }

    private var wifiNameBinding: Binding<String> {
        Binding(
            get: { viewModel.checklistState.homeWiFiName ?? "" },
            set: { viewModel.checklistState.homeWiFiName = $0.isEmpty ? nil : $0 }
        )
    }

    private func addItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.addChecklistItem(title: trimmed)
        newItemTitle = ""
        showAddItem = false
    }
}
