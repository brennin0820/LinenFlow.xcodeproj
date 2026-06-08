import SwiftUI

struct DurationPickerView: View {
    let title: String
    let subtitle: String?
    @Binding var minutes: Int
    let range: ClosedRange<Int>
    let step: Int

    init(
        title: String,
        subtitle: String? = nil,
        minutes: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 5
    ) {
        self.title = title
        self.subtitle = subtitle
        self._minutes = minutes
        self.range = range
        self.step = step
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(HimmerFlowColors.heroText)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(HimmerFlowColors.mutedText)
                }
            }

            HStack(spacing: 16) {
                Stepper(value: $minutes, in: range, step: step) {
                    Text(formattedDuration)
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(HimmerFlowColors.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .labelsHidden()
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(formattedDuration)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                minutes = min(minutes + step, range.upperBound)
            case .decrement:
                minutes = max(minutes - step, range.lowerBound)
            @unknown default:
                break
            }
        }
    }

    private var formattedDuration: String {
        if minutes >= 60 {
            let hours = minutes / 60
            let rem = minutes % 60
            if rem == 0 { return "\(hours) hr" }
            return "\(hours) hr \(rem) min"
        }
        return "\(minutes) min"
    }
}

struct HimmerFlowDurationSettingsView: View {
    @Bindable var settings: ShiftPlannerSettings
    var onSave: () async -> Void = {}

    var body: some View {
        Form {
            Section {
                DurationPickerView(
                    title: "Sleep",
                    subtitle: "Target sleep before your shift",
                    minutes: $settings.sleepDurationMinutes,
                    range: 240...600,
                    step: 15
                )
                DurationPickerView(
                    title: "Wind down before sleep",
                    minutes: $settings.preSleepWindDownMinutes,
                    range: 0...120,
                    step: 5
                )
            }

            Section("Get ready & leave") {
                DurationPickerView(
                    title: "Get ready",
                    minutes: $settings.getReadyDurationMinutes,
                    range: 15...120,
                    step: 5
                )
                DurationPickerView(
                    title: "Walk to car",
                    minutes: $settings.walkToCarMinutes,
                    range: 0...30,
                    step: 1
                )
                DurationPickerView(
                    title: "Commute estimate",
                    subtitle: "Manual drive or transit time",
                    minutes: $settings.commuteDurationMinutes,
                    range: 0...180,
                    step: 5
                )
            }

            Section("Arrival") {
                DurationPickerView(
                    title: "Parking + walk",
                    minutes: $settings.parkingWalkMinutes,
                    range: 0...45,
                    step: 5
                )
                DurationPickerView(
                    title: "Walk in",
                    minutes: $settings.walkInMinutes,
                    range: 0...30,
                    step: 1
                )
                DurationPickerView(
                    title: "Arrival buffer",
                    subtitle: "Be early before clock-in",
                    minutes: $settings.arrivalBufferMinutes,
                    range: 0...60,
                    step: 5
                )
            }

            Section("After shift") {
                DurationPickerView(
                    title: "Wind down after shift",
                    minutes: $settings.beDownMinutesAfterShift,
                    range: 0...180,
                    step: 15
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(HimmerFlowColors.background)
        .navigationTitle("Durations")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings.sleepDurationMinutes) { _, _ in persist() }
        .onChange(of: settings.getReadyDurationMinutes) { _, _ in persist() }
        .onChange(of: settings.commuteDurationMinutes) { _, _ in persist() }
        .onChange(of: settings.walkToCarMinutes) { _, _ in persist() }
        .onChange(of: settings.parkingWalkMinutes) { _, _ in persist() }
        .onChange(of: settings.walkInMinutes) { _, _ in persist() }
        .onChange(of: settings.arrivalBufferMinutes) { _, _ in persist() }
        .onChange(of: settings.preSleepWindDownMinutes) { _, _ in persist() }
        .onChange(of: settings.beDownMinutesAfterShift) { _, _ in persist() }
    }

    private func persist() {
        Task { await onSave() }
    }
}
