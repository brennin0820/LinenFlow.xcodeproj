import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct LeavingChecklistSheet: View {
    @Bindable public var viewModel: SmartShiftAlarmPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive

    public var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        // Times hero
                        if let plan = viewModel.heroDisplayPlan {
                            PremiumCard(accentColor: .green) {
                                VStack(spacing: 4) {
                                    TimeValueRow(label: "Target Arrival", time: plan.targetArrivalTime, tint: .cyan, isProminent: true, systemImage: "mappin.circle.fill")
                                    Divider().background(Color.white.opacity(0.06))
                                    TimeValueRow(label: "Walk to Car", time: plan.walkToCarTime, tint: .green, isProminent: true, systemImage: "figure.walk")
                                    Divider().background(Color.white.opacity(0.06))
                                    TimeValueRow(label: "Start Driving", time: plan.startDrivingTime, tint: .orange, isProminent: true, systemImage: "car.fill")
                                }
                            }
                        }

                        // Checklist items
                        PremiumCard(accentColor: .green) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Text("Before you leave")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    EditButton()
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.green)
                                }
                                .padding(.bottom, 12)

                                if viewModel.activeChecklistItems.isEmpty {
                                    EmptyStateView(
                                        systemImage: "checklist",
                                        title: "No active items",
                                        message: "Enable items to see them here."
                                    )
                                } else {
                                    ForEach(viewModel.activeChecklistItems) { item in
                                        ChecklistItemRow(
                                            item: item,
                                            isChecked: viewModel.isChecked(item)
                                        ) {
                                            withAnimation(.snappy(duration: 0.18)) {
                                                viewModel.toggleChecked(item)
                                            }
                                        }
                                        if item.id != viewModel.activeChecklistItems.last?.id {
                                            Divider().background(Color.white.opacity(0.06))
                                        }
                                    }
                                    .onDelete { offsets in
                                        viewModel.deleteChecklistItems(at: offsets)
                                    }
                                }
                            }
                        }

                        // All items management
                        PremiumCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("All Items")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.78))
                                ForEach(viewModel.checklistState.items) { item in
                                    ChecklistItemEditRow(item: item) {
                                        viewModel.toggleChecklistItemEnabled(item)
                                    }
                                    if item.id != viewModel.checklistState.items.last?.id {
                                        Divider().background(Color.white.opacity(0.06))
                                    }
                                }
                            }
                        }

                        // Actions
                        VStack(spacing: 10) {
                            Button(action: { viewModel.openWaze() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "car.fill")
                                    Text("Open Maps")
                                    Spacer()
                                    Image(systemName: "arrow.up.right.circle.fill")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 18)
                                .background(
                                    LinearGradient(colors: [.cyan, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!viewModel.isWorkAddressSet && viewModel.commutePlan.wazeDestinationMode == .searchAddress)

                            Button {
                                dismiss()
                            } label: {
                                Text("All Set")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Before You Leave")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .environment(\.editMode, $editMode)
        }
        .preferredColorScheme(.dark)
    }
}
