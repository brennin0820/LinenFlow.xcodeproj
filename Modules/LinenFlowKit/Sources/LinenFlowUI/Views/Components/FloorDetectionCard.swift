import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct FloorDetectionCard: View {
    public let state: FloorSensingState
    public let deliveryFloors: [Int]
    public let onCorrectFloor: (Int) -> Void

    private var sortedFloors: [Int] {
        Array(Set(deliveryFloors)).sorted()
    }

    private var confidenceTint: Color {
        switch state.confidence {
        case .unavailable: return .gray
        case .needsCorrection: return .orange
        case .low: return .yellow
        case .medium: return .cyan
        case .high: return .green
        }
    }

    public var body: some View {
        PremiumCard(accentColor: confidenceTint, isCurrent: state.isActive) {
            VStack(alignment: .leading, spacing: 12) {
                headerRow

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Floor \(state.estimatedFloor)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.72)
                            .lineLimit(1)
                            .accessibilityLabel("Estimated floor \(state.estimatedFloor)")

                        if let delta = altitudeDeltaSubtitle {
                            Text(delta)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.52))
                        }
                    }

                    Spacer(minLength: 8)

                    correctionControls
                }

                Text(state.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            Image(systemName: state.isAvailable ? "sensor.fill" : "sensor.tag.radiowaves.forward.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(confidenceTint)
                .frame(width: 34, height: 34)
                .background(confidenceTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Floor Detection")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(state.towerName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
            }

            Spacer()

            confidenceBadge
        }
    }

    private var confidenceBadge: some View {
        Text(confidenceLabel)
            .font(.caption.weight(.bold))
            .foregroundStyle(confidenceTint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(confidenceTint.opacity(0.14), in: Capsule())
            .accessibilityLabel("Confidence \(confidenceLabel)")
    }

    private var confidenceLabel: String {
        switch state.confidence {
        case .unavailable: return "Unavailable"
        case .needsCorrection: return "Needs correction"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    @ViewBuilder
    private var correctionControls: some View {
        if state.isAvailable, !sortedFloors.isEmpty {
            HStack(spacing: 8) {
                correctionButton(systemImage: "minus") {
                    onCorrectFloor(adjacentFloor(from: state.estimatedFloor, direction: -1))
                }
                .disabled(!canStep(from: state.estimatedFloor, direction: -1))

                Text("\(state.estimatedFloor)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(minWidth: 36)

                correctionButton(systemImage: "plus") {
                    onCorrectFloor(adjacentFloor(from: state.estimatedFloor, direction: 1))
                }
                .disabled(!canStep(from: state.estimatedFloor, direction: 1))
            }
            .accessibilityLabel("Correct floor")
            .accessibilityHint("Use plus and minus to set the current floor for barometer sensing.")
        }
    }

    private var altitudeDeltaSubtitle: String? {
        guard state.isAvailable else { return nil }
        let delta = state.altitudeDeltaMeters
        let sign = delta >= 0 ? "+" : ""
        return String(format: "Δ altitude %@%.1f m · start floor %d", sign, delta, state.startFloor)
    }

    private func correctionButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func adjacentFloor(from floor: Int, direction: Int) -> Int {
        let floors = sortedFloors
        guard !floors.isEmpty else { return floor }
        let anchored = FloorSensingEstimator.nearestValidFloor(to: floor, in: floors)
        guard let index = floors.firstIndex(of: anchored) else { return anchored }
        let nextIndex = min(max(index + direction, 0), floors.count - 1)
        return floors[nextIndex]
    }

    private func canStep(from floor: Int, direction: Int) -> Bool {
        let floors = sortedFloors
        guard let index = floors.firstIndex(of: FloorSensingEstimator.nearestValidFloor(to: floor, in: floors)) else {
            return false
        }
        let nextIndex = index + direction
        return nextIndex >= 0 && nextIndex < floors.count
    }
}
