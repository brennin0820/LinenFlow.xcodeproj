import SwiftUI

struct TodayShiftPlanCard: View {
    @Bindable var viewModel: SmartShiftAlarmPlannerViewModel
    let onOpenWaze: () -> Void

    var body: some View {
        if viewModel.isTodayWorkday, let plan = viewModel.todayPlan {
            workNightCard(plan: plan)
        } else {
            offDayCard
        }
    }

    // MARK: - Work Night Hero

    private func workNightCard(plan: WorkdayPlan) -> some View {
        let towerColor = WorkScheduleTowerColor.color(for: plan.assignedTowerName)
        return PremiumCard(accentColor: towerColor) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            shiftStatusBadge("Work Night", icon: "moon.stars.fill", color: towerColor)
                            Spacer()
                            Text(Date.now.formatted(.dateTime.weekday(.wide)))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        Text(plan.shiftStartDateTime.formatted(.dateTime.weekday(.wide)))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("\(plan.shiftStartDateTime.formatted(date: .omitted, time: .shortened)) – \(plan.shiftEndDateTime.formatted(date: .omitted, time: .shortened)) next day")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }

                Divider().background(Color.white.opacity(0.08))

                // Tower row
                if plan.assignedTowerName != "Unassigned" {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(towerColor)
                            .frame(width: 22, height: 22)
                            .background(towerColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        Text(plan.assignedTowerName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        shiftStatusBadge("Tower Assigned", icon: "checkmark.circle.fill", color: towerColor)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                            .frame(width: 22, height: 22)
                            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        Text("No tower assigned")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                        Spacer()
                        shiftStatusBadge("Unassigned", icon: "exclamationmark.triangle.fill", color: .orange)
                    }
                }

                // Live phase banner
                TimelineView(.everyMinute) { context in
                    let phase = plan.phase(at: context.date)
                    let next = plan.nextKeyEvent(at: context.date)
                    let phaseColor: Color = phase.isUrgent ? .orange : towerColor
                    HStack(spacing: 10) {
                        Image(systemName: phase.systemImage)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(phaseColor)
                            .frame(width: 32, height: 32)
                            .background(phaseColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(phase.label.uppercased())
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(phaseColor)
                                .tracking(0.5)
                            if let next {
                                Text("\(next.label) in \(WorkdayPlan.countdownString(from: context.date, to: next.time))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .contentTransition(.numericText())
                            } else {
                                Text("Shift complete")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                        }
                        Spacer()
                        if let next {
                            Text(next.time.formatted(date: .omitted, time: .shortened))
                                .font(.callout.weight(.bold).monospacedDigit())
                                .foregroundStyle(phaseColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(phaseColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(phaseColor.opacity(0.16), lineWidth: 1))
                    .animation(.easeInOut(duration: 0.3), value: phase)
                }

                Divider().background(Color.white.opacity(0.08))

                // Key times grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    heroTimeTile("Target Arrival", plan.targetArrivalTime, tint: towerColor)
                    heroTimeTile("Get Ready", plan.startGettingReadyTime, tint: .cyan)
                    heroTimeTile("Walk to Car", plan.walkToCarTime, tint: .green)
                    heroTimeTile("Start Driving", plan.startDrivingTime, tint: .orange)
                }

                // Quick adjust + Maps action row
                HStack(spacing: 8) {
                    quickAdjustButton("−5m", systemImage: "minus.circle.fill", tint: .cyan) {
                        adjustTargetArrival(minutes: -5)
                    }
                    quickAdjustButton("+5m", systemImage: "plus.circle.fill", tint: .cyan) {
                        adjustTargetArrival(minutes: 5)
                    }
                    quickAdjustButton("Leave Now", systemImage: "figure.walk.motion", tint: .orange) {
                        setTargetArrivalFromNow()
                    }
                }

                Button(action: onOpenWaze) {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.subheadline.weight(.semibold))
                        Text("Open Maps")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        LinearGradient(
                            colors: [towerColor.opacity(0.75), towerColor.opacity(0.45)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.isWorkAddressSet && viewModel.commutePlan.wazeDestinationMode == .searchAddress)
            }
        }
    }

    private func quickAdjustButton(_ title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
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

    private func adjustTargetArrival(minutes: Int) {
        let current = viewModel.targetArrivalDate()
        let adjusted = current.addingTimeInterval(Double(minutes) * 60)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: adjusted)
        viewModel.commutePlan.targetArrivalHour = comps.hour ?? viewModel.commutePlan.targetArrivalHour
        viewModel.commutePlan.targetArrivalMinute = comps.minute ?? viewModel.commutePlan.targetArrivalMinute
        viewModel.save()
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func setTargetArrivalFromNow() {
        let driveMinutes = max(1, viewModel.commutePlan.manualEstimatedDriveMinutes)
        let walkMinutes = max(0, viewModel.commutePlan.walkToCarMinutes)
        let projected = Date.now.addingTimeInterval(Double(driveMinutes + walkMinutes) * 60)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: projected)
        viewModel.commutePlan.targetArrivalHour = comps.hour ?? viewModel.commutePlan.targetArrivalHour
        viewModel.commutePlan.targetArrivalMinute = comps.minute ?? viewModel.commutePlan.targetArrivalMinute
        viewModel.save()
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    private func heroTimeTile(_ label: String, _ time: Date, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.6)
            Text(time.formatted(date: .omitted, time: .shortened))
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .animation(.snappy, value: time)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Off Day

    private var offDayCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    shiftStatusBadge("Off Tonight", icon: "moon.zzz.fill", color: .indigo)
                    Spacer()
                    Text(Date.now.formatted(.dateTime.weekday(.wide)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Text("Off Tonight")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                if let nextPlan = viewModel.nextWorkdayPlan {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.blue)
                            .frame(width: 22, height: 22)
                            .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        Text("Next work night: \(nextPlan.weekdayName) \(nextPlan.shiftStartDateTime.formatted(date: .omitted, time: .shortened))")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func shiftStatusBadge(_ label: String, icon: String, color: Color) -> some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.22), lineWidth: 1))
    }

}
