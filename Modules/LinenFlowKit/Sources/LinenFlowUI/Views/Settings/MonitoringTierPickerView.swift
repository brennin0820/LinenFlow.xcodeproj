import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct MonitoringTierPickerView: View {
    @Binding public var tier: ShiftPlannerSettings.MonitoringTier
    public var onChange: () async -> Void = {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location monitoring")
                .font(.headline.weight(.semibold))
                .foregroundStyle(HimmerFlowColors.secondaryText)

            ForEach(ShiftPlannerSettings.MonitoringTier.allCases, id: \.self) { option in
                tierRow(option)
            }
        }
    }

    private func tierRow(_ option: ShiftPlannerSettings.MonitoringTier) -> some View {
        Button {
            tier = option
            Task { await onChange() }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: tier == option ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(tier == option ? HimmerFlowColors.accent : HimmerFlowColors.mutedText)

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(HimmerFlowColors.heroText)
                    Text(description(for: option))
                        .font(.footnote)
                        .foregroundStyle(HimmerFlowColors.mutedText)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                tier == option ? HimmerFlowColors.accent.opacity(0.12) : HimmerFlowColors.surface,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(tier == option ? HimmerFlowColors.accent : HimmerFlowColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.displayName). \(description(for: option))")
        .accessibilityAddTraits(tier == option ? .isSelected : [])
    }

    private func description(for tier: ShiftPlannerSettings.MonitoringTier) -> String {
        switch tier {
        case .manual:
            return "Time-based reminders only. No background location."
        case .smart:
            return "Detect leaving home and arriving at work with geofences."
        case .activeCommute:
            return "Smart geofences plus rough ETA updates during your commute."
        }
    }
}

public struct HimmerFlowPlannerSettingsView: View {
    @Bindable public var settings: ShiftPlannerSettings
    public var orchestrator: ShiftOrchestrator
    @State private var showHomeLocationPicker = false
    @State private var showLocationPermission = false

    public var body: some View {
        List {
            Section("Monitoring") {
                MonitoringTierPickerView(tier: $settings.monitoringTier) {
                    await reconcileSettings()
                }
                .listRowBackground(HimmerFlowColors.surface)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            Section("Home location") {
                if let home = settings.homeLocation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(home.label)
                            .font(.body.weight(.semibold))
                        Text("Radius \(Int(home.radiusMeters)) m")
                            .font(.caption)
                            .foregroundStyle(HimmerFlowColors.mutedText)
                    }
                    .listRowBackground(HimmerFlowColors.surface)
                } else {
                    Text("Not set")
                        .foregroundStyle(HimmerFlowColors.mutedText)
                        .listRowBackground(HimmerFlowColors.surface)
                }

                Button("Set home location") {
                    showHomeLocationPicker = true
                }
                .listRowBackground(HimmerFlowColors.surface)

                if settings.monitoringTier != .manual {
                    Button("Location permissions") {
                        showLocationPermission = true
                    }
                    .listRowBackground(HimmerFlowColors.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(HimmerFlowColors.background)
        .navigationTitle("Shift Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showHomeLocationPicker) {
            NavigationStack {
                LocationPickerView(
                    title: "Home",
                    locationType: .home,
                    existing: settings.homeLocation
                ) { saved in
                    settings.homeLocation = saved
                    await reconcileSettings()
                }
            }
        }
        .sheet(isPresented: $showLocationPermission) {
            LocationPermissionView()
        }
    }

    private func reconcileSettings() async {
        await orchestrator.reconcile(trigger: .settingsChanged)
    }
}
