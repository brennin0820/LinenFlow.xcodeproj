import SwiftUI
import WidgetKit

#if canImport(ActivityKit)
import ActivityKit

struct ShiftActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShiftActivityAttributes.self) { context in
            ShiftLiveActivityLockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(ShiftActivityPalette.nightBase)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ShiftExpandedLeadingView(attributes: context.attributes, state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ShiftCountdownView(target: context.state.nextActionTime)
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.currentPhase.displayName)
                        .font(.headline.weight(.heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ShiftExpandedBottomView(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                Text(context.state.statusEmoji)
                    .font(.body)
                    .accessibilityLabel(context.state.currentPhase.displayName)
            } compactTrailing: {
                ShiftCountdownView(target: context.state.nextActionTime, compact: true)
            } minimal: {
                ShiftCountdownView(target: context.state.nextActionTime, compact: true)
            }
            .keylineTint(ShiftActivityPalette.accent)
        }
    }
}

// MARK: - Lock Screen

private struct ShiftLiveActivityLockScreenView: View {
    let attributes: ShiftActivityAttributes
    let state: ShiftActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text(state.statusEmoji)
                    .font(.largeTitle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(attributes.shiftName)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(state.currentPhase.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer(minLength: 0)

                ShiftCountdownView(target: state.nextActionTime)
            }

            Text(state.nextActionLabel)
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)

            ShiftProgressBar(fraction: state.progressFraction)

            HStack {
                Text("Clock in")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text(HimmerFlowDateFormatting.timeString(attributes.clockInTime))
                    .font(.caption.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [ShiftActivityPalette.nightBase, ShiftActivityPalette.nightElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.currentPhase.displayName). \(state.nextActionLabel). Clock in at \(HimmerFlowDateFormatting.timeString(attributes.clockInTime)).")
    }
}

// MARK: - Dynamic Island Regions

private struct ShiftExpandedLeadingView: View {
    let attributes: ShiftActivityAttributes
    let state: ShiftActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(attributes.shiftName)
                .font(.headline.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text(state.nextActionLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }
}

private struct ShiftExpandedBottomView: View {
    let attributes: ShiftActivityAttributes
    let state: ShiftActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ShiftProgressBar(fraction: state.progressFraction)
            HStack {
                Text("Clock in \(HimmerFlowDateFormatting.timeString(attributes.clockInTime))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Text(state.statusEmoji)
                    .font(.caption)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct ShiftCountdownView: View {
    let target: Date
    var compact: Bool = false

    var body: some View {
        if target > .now {
            Text(timerInterval: Date.now ... target, countsDown: true)
                .font(compact ? .caption.weight(.heavy).monospacedDigit() : .title3.weight(.heavy).monospacedDigit())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.trailing)
        } else {
            Text("Now")
                .font(compact ? .caption.weight(.heavy) : .title3.weight(.heavy))
                .foregroundStyle(ShiftActivityPalette.accent)
        }
    }
}

private struct ShiftProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(ShiftActivityPalette.accent)
                    .frame(width: max(proxy.size.width * min(max(fraction, 0), 1), 3))
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Shift progress")
        .accessibilityValue("\(Int(min(max(fraction, 0), 1) * 100)) percent")
    }
}

private enum ShiftActivityPalette {
    static let nightBase = Color(red: 0.07, green: 0.08, blue: 0.12)
    static let nightElevated = Color(red: 0.11, green: 0.12, blue: 0.18)
    static let accent = Color(red: 0.35, green: 0.78, blue: 0.98)
}

// MARK: - Previews

#if DEBUG
private extension ShiftActivityAttributes {
    static var previewAttributes: ShiftActivityAttributes {
        ShiftActivityAttributes(shiftName: "Night Shift", clockInTime: .now.addingTimeInterval(3600))
    }
}

private extension ShiftActivityAttributes.ContentState {
    static var leavePreview: ShiftActivityAttributes.ContentState {
        ShiftActivityAttributes.ContentState(
            currentPhase: .leave,
            nextActionLabel: "Leave in 23 min",
            nextActionTime: .now.addingTimeInterval(1380),
            progressFraction: 0.42,
            statusEmoji: "🚗"
        )
    }
}

struct ShiftActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        ShiftLiveActivityLockScreenView(
            attributes: .previewAttributes,
            state: .leavePreview
        )
        .previewDisplayName("Lock Screen")
        .previewLayout(.sizeThatFits)
    }
}
#endif
#endif
