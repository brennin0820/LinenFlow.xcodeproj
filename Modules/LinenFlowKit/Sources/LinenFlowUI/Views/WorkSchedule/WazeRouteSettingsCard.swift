import SwiftUI
import CoreLocation
import LinenFlowCore
import LinenFlowEngine

public struct WazeRouteSettingsCard: View {
    @Bindable public var viewModel: SmartShiftAlarmPlannerViewModel
    @State private var locationService = LocationService()

    public var body: some View {
        PremiumCard(accentColor: .blue) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.blue.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Route Settings")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Navigation via Maps")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                }

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                // Destination mode picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Destination Mode")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(0.4)

                    Picker("Destination Mode", selection: $viewModel.commutePlan.wazeDestinationMode) {
                        ForEach(WazeDestinationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorScheme(.dark)
                }

                // Mode-specific input
                modeInput
                    .padding(.top, 12)

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                // Waze notes
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill").foregroundStyle(.blue.opacity(0.7))
                        Text("Maps handles live traffic and navigation. HimmerFlow plans alarms from your saved drive estimate and target arrival.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill").foregroundStyle(.blue.opacity(0.7))
                        Text("Open Maps before leaving for live traffic.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

                // Open Waze button
                Button(action: { viewModel.openWaze() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                        Text("Open in Maps")
                        Spacer()
                        Image(systemName: "arrow.up.right.circle.fill")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        LinearGradient(colors: [.blue, .blue.opacity(0.65)], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isWazeDisabled)
                .opacity(isWazeDisabled ? 0.5 : 1)

                if isWazeDisabled {
                    Text("Add work address to open Maps.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top, 6)
                }
            }
        }
        .onChange(of: viewModel.commutePlan.wazeDestinationMode) { _, _ in viewModel.save() }
        .onChange(of: viewModel.commutePlan.wazeSearchQuery) { _, _ in viewModel.save() }
        .onChange(of: viewModel.commutePlan.wazeLatitude) { _, _ in viewModel.save() }
        .onChange(of: viewModel.commutePlan.wazeLongitude) { _, _ in viewModel.save() }
    }

    @ViewBuilder
    private var modeInput: some View {
        switch viewModel.commutePlan.wazeDestinationMode {
        case .favWork:
            modeLabelCard("Uses your Work favorite saved in Maps.", icon: "star.fill", tint: .yellow)
        case .favHome:
            modeLabelCard("Uses your Home favorite saved in Maps.", icon: "house.fill", tint: .cyan)
        case .searchAddress:
            VStack(alignment: .leading, spacing: 6) {
                Text("Destination Address")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                TextField("Enter destination address", text: $viewModel.commutePlan.wazeSearchQuery)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .tint(.blue)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            }
        case .coordinates:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Coordinates")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Button {
                        Task {
                            if let coord = await locationService.fetchCurrentLocation() {
                                viewModel.commutePlan.wazeLatitude = coord.latitude
                                viewModel.commutePlan.wazeLongitude = coord.longitude
                                viewModel.save()
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if locationService.isLoading {
                                ProgressView().scaleEffect(0.72).tint(.blue)
                            } else {
                                Image(systemName: "location.fill")
                                    .font(.caption2.weight(.bold))
                            }
                            Text("Use Current")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(locationService.isLoading)
                }
                if let err = locationService.errorMessage {
                    Text(err)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latitude").font(.caption2).foregroundStyle(.white.opacity(0.5))
                        TextField("21.2830", value: $viewModel.commutePlan.wazeLatitude, format: .number)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .tint(.blue)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Longitude").font(.caption2).foregroundStyle(.white.opacity(0.5))
                        TextField("-157.8360", value: $viewModel.commutePlan.wazeLongitude, format: .number)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .tint(.blue)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
    }

    private var isWazeDisabled: Bool {
        switch viewModel.commutePlan.wazeDestinationMode {
        case .searchAddress:
            let query = viewModel.commutePlan.wazeSearchQuery
            let address = viewModel.commutePlan.workAddress
            return query.trimmingCharacters(in: .whitespaces).isEmpty &&
                   address.trimmingCharacters(in: .whitespaces).isEmpty
        default:
            return false
        }
    }

    private func modeLabelCard(_ text: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
