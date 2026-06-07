import SwiftUI

struct CommutePlanCard: View {
    @Bindable var viewModel: SmartShiftAlarmPlannerViewModel
    @State private var showAddressSheet = false

    var body: some View {
        PremiumCard(accentColor: .cyan) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.cyan.opacity(0.75), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Commute Plan")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("From \(viewModel.displayHomeLabel) to \(viewModel.commutePlan.workLabel)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Button { showAddressSheet = true } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                // Target Arrival (large/prominent)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Arrival".uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.cyan.opacity(0.8))
                        .tracking(0.8)
                    DatePicker(
                        "",
                        selection: targetArrivalBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.cyan)
                    .padding(.vertical, 4)
                }

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                // Minute controls
                VStack(spacing: 2) {
                    minuteRow("Drive Estimate", value: $viewModel.commutePlan.manualEstimatedDriveMinutes, range: 1...120, tint: .orange)
                    minuteRow("Walk to Car", value: $viewModel.commutePlan.walkToCarMinutes, range: 0...30, tint: .green)
                    minuteRow("Safety Buffer", value: $viewModel.commutePlan.safetyBufferMinutes, range: 0...60, tint: .yellow)
                    minuteRow("Prep Time", value: $viewModel.commutePlan.prepMinutes, range: 0...120, tint: .purple)
                    minuteRow("Leave Soon Alert", value: $viewModel.commutePlan.leaveSoonAlertMinutes, range: 1...30, tint: .red)
                    minuteRow("Shift Soon Alert", value: $viewModel.commutePlan.shiftSoonAlertMinutes, range: 1...30, tint: .red)
                }

                if let plan = viewModel.heroDisplayPlan {
                    Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                    // Calculated times
                    VStack(spacing: 0) {
                        TimeValueRow(label: "Get Ready", time: plan.startGettingReadyTime, tint: .cyan, isProminent: true, systemImage: "clock.fill")
                        Divider().background(Color.white.opacity(0.06))
                        TimeValueRow(label: "Walk to Car", time: plan.walkToCarTime, tint: .green, isProminent: true, systemImage: "figure.walk")
                        Divider().background(Color.white.opacity(0.06))
                        TimeValueRow(label: "Start Driving", time: plan.startDrivingTime, tint: .orange, isProminent: true, systemImage: "car.fill")
                        Divider().background(Color.white.opacity(0.06))
                        TimeValueRow(label: "Target Arrival", time: plan.targetArrivalTime, tint: .cyan, isProminent: true, systemImage: "mappin.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddressSheet) {
            AddressEditSheet(viewModel: viewModel)
        }
        .onChange(of: viewModel.commutePlan.manualEstimatedDriveMinutes) { _, _ in viewModel.save() }
        .onChange(of: viewModel.commutePlan.walkToCarMinutes) { _, _ in viewModel.save() }
        .onChange(of: viewModel.commutePlan.safetyBufferMinutes) { _, _ in viewModel.save() }
        .onChange(of: viewModel.commutePlan.prepMinutes) { _, _ in viewModel.save() }
        .onChange(of: viewModel.commutePlan.leaveSoonAlertMinutes) { _, _ in viewModel.save() }
        .onChange(of: viewModel.commutePlan.shiftSoonAlertMinutes) { _, _ in viewModel.save() }
    }

    // MARK: - Helpers

    private var targetArrivalBinding: Binding<Date> {
        Binding(
            get: { viewModel.targetArrivalDate() },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                viewModel.commutePlan.targetArrivalHour = comps.hour ?? 22
                viewModel.commutePlan.targetArrivalMinute = comps.minute ?? 45
                viewModel.save()
            }
        )
    }

    private func minuteRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>, tint: Color) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
            Spacer()
            Stepper(
                "\(value.wrappedValue) min",
                value: value,
                in: range
            )
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .foregroundStyle(.white)
            .tint(tint)
            .frame(maxWidth: 180)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Address Edit Sheet

private struct AddressEditSheet: View {
    @Bindable var viewModel: SmartShiftAlarmPlannerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        PremiumCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Work Address", systemImage: "mappin.and.ellipse")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                TextField("Work address", text: $viewModel.commutePlan.workAddress)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .tint(.cyan)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }

                        PremiumCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Home Address (reference only)", systemImage: "house.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Used as reference. Maps can start from your current location.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                                TextField("Home address", text: $viewModel.commutePlan.homeAddress)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .tint(.cyan)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }

                        PremiumCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(.green)
                                Text("Privacy Note")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Schedule and commute settings stay on this device unless you export or share them.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Edit Addresses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.save()
                        dismiss()
                    }
                    .foregroundStyle(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
