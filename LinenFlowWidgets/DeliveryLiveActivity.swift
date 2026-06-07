import ActivityKit
import WidgetKit
import SwiftUI

struct DeliveryLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeliveryLiveActivityAttributes.self) { context in
            DeliveryLockScreenView(context: context)
                .containerBackground(.black, for: .widget)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DeliveryExpandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    DeliveryExpandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    DeliveryExpandedBottom(context: context)
                }
            } compactLeading: {
                DeliveryCompactLeading(context: context)
            } compactTrailing: {
                DeliveryCompactTrailing(context: context)
            } minimal: {
                DeliveryMinimal(context: context)
            }
        }
    }
}

// MARK: - Lock Screen / Notification Center

private struct DeliveryLockScreenView: View {
    let context: ActivityViewContext<DeliveryLiveActivityAttributes>

    var body: some View {
        let state = context.state
        let accent = Color(hex: context.attributes.towerAccentHex) ?? .blue

        HStack(spacing: 14) {
            ZStack {
                FloorProgressArc(fraction: state.progressFraction, accentColor: accent, lineWidth: 5)
                VStack(spacing: 0) {
                    Text("\(state.completedFloors)")
                        .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("/ \(state.totalFloors)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(context.attributes.towerName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    if state.isActive {
                        Circle().fill(.green).frame(width: 6, height: 6)
                    }
                }
                Text(state.paceStatusLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(paceColor(state.paceStatusLabel))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(paceColor(state.paceStatusLabel).opacity(0.15), in: Capsule())
                if let focus = state.currentItemFocus {
                    Text(focus)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(timeText(state.minutesToTarget))
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                Text("remaining")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(14)
    }
}

// MARK: - Dynamic Island Expanded

private struct DeliveryExpandedLeading: View {
    let context: ActivityViewContext<DeliveryLiveActivityAttributes>

    var body: some View {
        let accent = Color(hex: context.attributes.towerAccentHex) ?? .blue
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.towerName)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
            Text("\(context.state.completedFloors)/\(context.state.totalFloors)")
                .font(.caption2.weight(.semibold).monospacedDigit())
                .foregroundStyle(accent)
        }
        .padding(.leading, 4)
    }
}

private struct DeliveryExpandedTrailing: View {
    let context: ActivityViewContext<DeliveryLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(timeText(context.state.minutesToTarget))
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
            Text(context.state.paceStatusLabel)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(paceColor(context.state.paceStatusLabel))
        }
        .padding(.trailing, 4)
    }
}

private struct DeliveryExpandedBottom: View {
    let context: ActivityViewContext<DeliveryLiveActivityAttributes>

    var body: some View {
        let accent = Color(hex: context.attributes.towerAccentHex) ?? .blue
        VStack(spacing: 3) {
            ProgressView(value: context.state.progressFraction)
                .progressViewStyle(.linear)
                .tint(accent)
            if let focus = context.state.currentItemFocus {
                Text("Now: \(focus)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.60))
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Dynamic Island Compact

private struct DeliveryCompactLeading: View {
    let context: ActivityViewContext<DeliveryLiveActivityAttributes>

    var body: some View {
        let accent = Color(hex: context.attributes.towerAccentHex) ?? .blue
        ZStack {
            Circle().stroke(Color.white.opacity(0.20), lineWidth: 2)
            Circle()
                .trim(from: 0, to: context.state.progressFraction)
                .stroke(accent, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 20, height: 20)
        .padding(.leading, 4)
    }
}

private struct DeliveryCompactTrailing: View {
    let context: ActivityViewContext<DeliveryLiveActivityAttributes>

    var body: some View {
        Text("\(context.state.remainingFloors)fl")
            .font(.caption2.weight(.bold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.trailing, 4)
    }
}

private struct DeliveryMinimal: View {
    let context: ActivityViewContext<DeliveryLiveActivityAttributes>

    var body: some View {
        let accent = Color(hex: context.attributes.towerAccentHex) ?? .blue
        ZStack {
            Circle().stroke(Color.white.opacity(0.20), lineWidth: 2)
            Circle()
                .trim(from: 0, to: context.state.progressFraction)
                .stroke(accent, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Helpers

private func timeText(_ minutesToTarget: Int) -> String {
    let hours = minutesToTarget / 60
    let mins = minutesToTarget % 60
    if hours > 0 { return "\(hours)h \(mins)m" }
    return "\(minutesToTarget)m"
}
