import SwiftUI
import SwiftData

struct TowerCalibrationView: View {
    @Query(sort: \Tower.name) private var towers: [Tower]

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(spacing: 14) {
                    PremiumCard(accentColor: .orange) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.orange)
                                .frame(width: 34, height: 34)
                                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sensing Not Active")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Automatic floor sensing is not active yet. These values prepare future barometer calibration.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.65))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    ForEach(towers) { tower in
                        TowerCalibrationCard(tower: tower)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Tower Calibration")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Per-tower card

private struct TowerCalibrationCard: View {
    @Bindable var tower: Tower
    @Environment(\.modelContext) private var modelContext
    @State private var showResetConfirmation = false

    var body: some View {
        PremiumCard(accentColor: towerColor) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(tower.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    confidencePill(tower.towerDataConfidence)
                }

                HStack(spacing: 8) {
                    calibFact(String(format: "%.2f m", tower.estimatedFloorHeightMeters), "height/floor")
                    calibFact(String(format: "%.2f m", tower.floorDetectionToleranceMeters), "tolerance")
                    calibFact(String(format: "%.1f m", tower.floorMovementConfidenceThresholdMeters), "min move")
                }

                if let lat = tower.latitude, let lon = tower.longitude {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.cyan)
                        Text(String(format: "%.5f, %.5f", lat, lon))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }

                if let notes = tower.towerDataNotes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.50))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider().background(Color.white.opacity(0.10))

                HStack(spacing: 8) {
                    calibEditStepper(
                        label: "Height",
                        value: $tower.estimatedFloorHeightMeters,
                        range: 2.4...5.0,
                        step: 0.01,
                        format: "%.2f m"
                    )

                    Button {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.72))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: tower.estimatedFloorHeightMeters) { _, _ in try? modelContext.save() }
        .confirmationDialog("Reset \(tower.name) calibration?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset Calibration", role: .destructive) {
                resetCalibration()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This restores the default sensing calibration values for this tower only. Saved logs are not changed.")
        }
    }

    private var towerColor: Color? {
        Color(hex: tower.identityColorHex ?? "")
    }

    private func calibFact(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func calibEditStepper(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String
    ) -> some View {
        Stepper(value: value, in: range, step: step) {
            Text("\(label): \(String(format: format, value.wrappedValue))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
        }
        .tint(.teal)
    }

    private func confidencePill(_ confidence: String) -> some View {
        let tint: Color = {
            switch confidence.lowercased() {
            case "high":   return .green
            case "medium": return .cyan
            case "low":    return .orange
            default:       return .white.opacity(0.45)
            }
        }()
        return Text(confidence)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
    }

    private func resetCalibration() {
        let defaults = DefaultData.towerCalibrations[tower.name]
        tower.estimatedFloorHeightMeters = defaults?.estimatedFloorHeightMeters ?? 3.1
        tower.floorDetectionToleranceMeters = defaults?.floorDetectionToleranceMeters ?? 0.45
        tower.floorMovementConfidenceThresholdMeters = defaults?.floorMovementConfidenceThresholdMeters ?? 1.2
        try? modelContext.save()
    }
}
