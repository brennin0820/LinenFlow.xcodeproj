import ActivityKit
import SwiftUI
import WidgetKit
import AppIntents

struct HimmerFlowDeliveryAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var completedFloors: Int
        var remainingFloors: Int
        var currentItemName: String?
        var currentItemNames: [String]? = nil
        var currentTripItemNames: [String]? = nil
        var currentFloorNumber: Int? = nil
        var currentFloorDeliveryAmounts: [WidgetFloorDeliveryAmount]? = nil
        var currentTripRemainingBundles: Int? = nil
        var currentTripTotalBundles: Int? = nil
        var nextCarryGroupTitle: String?
        var statusText: String
        var targetTime: Date?
        var lastUpdated: Date
        var isActiveSession: Bool
    }

    var towerName: String
    var floorCount: Int
    var towerColorHex: String?
}

struct HimmerFlow_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HimmerFlowDeliveryAttributes.self) { context in
            LiveActivityContent(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(HimmerFlowWidgetDesignSystem.Palette.nightBase)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let snapshot = operationalSnapshot(attributes: context.attributes, state: context.state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(context.attributes.towerName)
                            .font(.headline.weight(.heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(tripItems(for: context.state).joined(separator: " · "))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    floorIslandAction(floor: context.state.currentFloorNumber, accentColor: urgencyColor(attributes: context.attributes, state: context.state))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        thinProgressBar(
                            completedFloors: context.state.completedFloors,
                            floorCount: context.attributes.floorCount,
                            accentColor: urgencyColor(attributes: context.attributes, state: context.state)
                        )
                        Text(progressText(completedFloors: context.state.completedFloors, floorCount: context.attributes.floorCount))
                            .font(.caption.weight(.heavy).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Text(snapshot.shortTowerName)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(urgencyColor(attributes: context.attributes, state: context.state))
                    .minimumScaleFactor(0.72)
            } compactTrailing: {
                Text(context.state.currentFloorNumber.map { "F\($0)" } ?? "Done")
                    .font(.caption.weight(.heavy).monospacedDigit())
                    .foregroundStyle(urgencyColor(attributes: context.attributes, state: context.state))
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.72)
            } minimal: {
                Text(context.state.currentFloorNumber.map { "\($0)" } ?? "OK")
                    .font(.caption.weight(.black).monospacedDigit())
                    .foregroundStyle(urgencyColor(attributes: context.attributes, state: context.state))
            }
            .keylineTint(urgencyColor(attributes: context.attributes, state: context.state))
        }
    }

    private func islandDetail(_ value: String, _ symbol: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func floorIslandAction(floor: Int?, accentColor: Color) -> some View {
        if let floor {
            if #available(iOSApplicationExtension 17.0, *) {
                Button(intent: CompleteCurrentFloorIntent(floorNumber: floor)) {
                    floorIslandLabel(floor: floor, accentColor: accentColor)
                }
                .buttonStyle(.plain)
            } else {
                floorIslandLabel(floor: floor, accentColor: accentColor)
            }
        } else {
            Text("Done")
                .font(.headline.weight(.heavy))
                .foregroundStyle(accentColor)
        }
    }

    private func floorIslandLabel(floor: Int, accentColor: Color) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(floor)")
                .font(.title2.weight(.black).monospacedDigit())
            Text("FLOOR")
                .font(.system(size: 9, weight: .heavy))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(accentColor.opacity(0.34), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct LiveActivityContent: View {
    let attributes: HimmerFlowDeliveryAttributes
    let state: HimmerFlowDeliveryAttributes.ContentState

    private var snapshot: OperationalShiftSnapshot {
        operationalSnapshot(attributes: attributes, state: state)
    }

    private var accentColor: Color {
        statusColor(attributes: attributes, state: state)
    }

    private var hasRouteComplete: Bool {
        attributes.floorCount > 0 && state.remainingFloors == 0 && state.completedFloors >= attributes.floorCount
    }

    private var currentFloorAmounts: [WidgetFloorDeliveryAmount] {
        Array((state.currentFloorDeliveryAmounts ?? [])
            .sorted { LinenIconLibrary.itemComesBefore($0.itemName, $1.itemName) }
            .prefix(2))
    }

    private var bundleProgressText: String? {
        guard let remaining = state.currentTripRemainingBundles,
              let total = state.currentTripTotalBundles,
              total > 0 else { return nil }
        return "\(remaining) / \(total) bdl left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 9) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accentColor)
                    .frame(width: 4)
                    .shadow(color: accentColor.opacity(0.45), radius: 7, x: 0, y: 0)

                VStack(alignment: .leading, spacing: 7) {
                    Text(attributes.towerName)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    activityTripItems
                }
            }

            if hasRouteComplete {
                activityRouteCompleteCard
            } else if let floor = state.currentFloorNumber, state.isActiveSession {
                activityFloorAction(floor: floor)
            } else {
                Text("No Active Delivery")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            activityProgressFooter
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    HimmerFlowWidgetDesignSystem.Palette.nightBase,
                    HimmerFlowWidgetDesignSystem.Palette.nightElevated
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var activityTripItems: some View {
        VStack(alignment: .leading, spacing: 3) {
            if tripItems(for: state).isEmpty {
                Text("Current Trip")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            } else {
                HStack(spacing: 6) {
                    ForEach(tripItems(for: state), id: \.self) { item in
                        activityItemInitialBadge(itemName: item)
                    }
                }
            }
        }
    }

    private var activityProgressFooter: some View {
        VStack(spacing: 6) {
            thinProgressBar(completedFloors: state.completedFloors, floorCount: attributes.floorCount, accentColor: accentColor)

            Text(progressText(completedFloors: state.completedFloors, floorCount: attributes.floorCount))
                .font(.caption.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .center)
                .contentTransition(.numericText())

            if let bundleProgressText {
                Text(bundleProgressText)
                    .font(.caption2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(accentColor.opacity(0.90))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .contentTransition(.numericText())
            }
        }
    }

    private var activityRouteCompleteCard: some View {
        VStack(spacing: 7) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 38, weight: .heavy))
                .foregroundStyle(accentColor)
            Text("Route Complete")
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("Completed Successfully")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)

            if #available(iOS 17.0, *) {
                Button(intent: UndoLastFloorIntent()) {
                    Text("Undo Last Floor")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.82))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.28), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func activityFloorAction(floor: Int) -> some View {
        if #available(iOS 17.0, *) {
            Button(intent: CompleteCurrentFloorIntent(floorNumber: floor)) {
                activityFloorCard(floor: floor)
            }
            .buttonStyle(.plain)
        } else {
            activityFloorCard(floor: floor)
        }
    }

    private func activityFloorCard(floor: Int) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text("FLOOR")
                    .font(.caption.weight(.heavy))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.66))
                Text("\(floor)")
                    .font(.system(size: 58, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            if !currentFloorAmounts.isEmpty {
                VStack(spacing: 4) {
                    ForEach(currentFloorAmounts, id: \.self) { amount in
                        HStack(spacing: 7) {
                            activityItemInitialBadge(itemName: amount.itemName)
                            Text(amount.amountText)
                                .font(.caption.weight(.heavy).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.86))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(accentColor.opacity(0.30), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private func activityItemInitialBadge(itemName: String) -> some View {
        Text(LinenIconLibrary.initials(forItem: itemName))
            .font(.system(size: 14, weight: .black, design: .monospaced))
            .foregroundStyle(LinenIconLibrary.color(forItem: itemName))
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .frame(width: 28, height: 28)
            .accessibilityLabel(itemName)
    }
}

private func thinProgressBar(completedFloors: Int, floorCount: Int, accentColor: Color) -> some View {
    GeometryReader { proxy in
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.10))
            Capsule()
                .fill(accentColor)
                .frame(width: max(proxy.size.width * progressFraction(completedFloors: completedFloors, floorCount: floorCount), 3))
        }
    }
    .frame(height: 4)
}

private struct MinimalProgressGlyph: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

private func progressFraction(_ context: ActivityViewContext<HimmerFlowDeliveryAttributes>) -> Double {
    progressFraction(completedFloors: context.state.completedFloors, floorCount: context.attributes.floorCount)
}

private func progressFraction(completedFloors: Int, floorCount: Int) -> Double {
    HimmerFlowWidgetDesignSystem.progressFraction(completedFloors: completedFloors, floorCount: floorCount)
}

private func progressText(completedFloors: Int, floorCount: Int) -> String {
    "\(completedFloors) / \(max(floorCount, 0))"
}

private func operationalSnapshot(
    attributes: HimmerFlowDeliveryAttributes,
    state: HimmerFlowDeliveryAttributes.ContentState
) -> OperationalShiftSnapshot {
    OperationalShiftStateEngine.snapshot(
        towerName: attributes.towerName,
        floorCount: attributes.floorCount,
        completedFloors: state.completedFloors,
        remainingFloors: state.remainingFloors,
        currentItemName: state.currentItemName,
        currentItemNames: state.currentItemNames,
        nextCarryGroupTitle: state.nextCarryGroupTitle,
        targetTime: state.targetTime,
        statusText: state.statusText,
        isActiveSession: state.isActiveSession
    )
}

private func isComplete(attributes: HimmerFlowDeliveryAttributes, state: HimmerFlowDeliveryAttributes.ContentState) -> Bool {
    operationalSnapshot(attributes: attributes, state: state).isComplete
}

private func urgencyColor(attributes: HimmerFlowDeliveryAttributes, state: HimmerFlowDeliveryAttributes.ContentState) -> Color {
    statusColor(attributes: attributes, state: state)
}

private func statusColor(attributes: HimmerFlowDeliveryAttributes, state: HimmerFlowDeliveryAttributes.ContentState) -> Color {
    WidgetDesignTokens.statusColor(
        for: operationalSnapshot(attributes: attributes, state: state),
        towerColorHex: attributes.towerColorHex
    )
}

private func countdownText(for state: HimmerFlowDeliveryAttributes.ContentState, compact: Bool) -> String {
    HimmerFlowWidgetDesignSystem.countdownText(targetTime: state.targetTime, fallback: state.statusText, compact: compact)
}

private func itemSummary(for state: HimmerFlowDeliveryAttributes.ContentState) -> String {
    let names = tripItems(for: state)
    guard !names.isEmpty else { return "No items queued" }
    return names.joined(separator: " · ")
}

private func tripItems(for state: HimmerFlowDeliveryAttributes.ContentState) -> [String] {
    let tripItems = state.currentTripItemNames ?? []
    let fallbackItems = state.currentItemNames ?? [state.currentItemName].compactMap { $0 }
    return Array((tripItems.isEmpty ? fallbackItems : tripItems)
        .sorted { LinenIconLibrary.itemComesBefore($0, $1) }
        .prefix(2))
}

private func shortTowerName(_ towerName: String) -> String {
    HimmerFlowWidgetDesignSystem.shortTowerName(towerName)
}

private extension HimmerFlowDeliveryAttributes {
    static var diamondPreview: HimmerFlowDeliveryAttributes {
        HimmerFlowDeliveryAttributes(towerName: "Diamond", floorCount: 15, towerColorHex: "#7C878E")
    }

    static var lagoonPreview: HimmerFlowDeliveryAttributes {
        HimmerFlowDeliveryAttributes(towerName: "Lagoon", floorCount: 12, towerColorHex: "#2F8C9D")
    }
}

private extension HimmerFlowDeliveryAttributes.ContentState {
    static var activePreview: HimmerFlowDeliveryAttributes.ContentState {
        var state = HimmerFlowDeliveryAttributes.ContentState(
            completedFloors: 9,
            remainingFloors: 6,
            currentItemName: "Bath Towels",
            nextCarryGroupTitle: "WC + HT Carry Trip",
            statusText: "9/15 floors complete",
            targetTime: Calendar.current.date(byAdding: .minute, value: 134, to: .now),
            lastUpdated: .now,
            isActiveSession: true
        )
        state.currentItemNames = ["Bath Towels", "Washcloth", "Hand Towel"]
        return state
    }

    static var nearTargetPreview: HimmerFlowDeliveryAttributes.ContentState {
        HimmerFlowDeliveryAttributes.ContentState(
            completedFloors: 11,
            remainingFloors: 4,
            currentItemName: "Double Sheets",
            nextCarryGroupTitle: "Duvet recovery carry",
            statusText: "11/15 floors complete",
            targetTime: Calendar.current.date(byAdding: .minute, value: 24, to: .now),
            lastUpdated: .now,
            isActiveSession: true
        )
    }

    static var completedPreview: HimmerFlowDeliveryAttributes.ContentState {
        HimmerFlowDeliveryAttributes.ContentState(
            completedFloors: 15,
            remainingFloors: 0,
            currentItemName: nil,
            nextCarryGroupTitle: nil,
            statusText: "Shift complete",
            targetTime: Calendar.current.date(byAdding: .minute, value: 12, to: .now),
            lastUpdated: .now,
            isActiveSession: false
        )
    }

    static var pausedPreview: HimmerFlowDeliveryAttributes.ContentState {
        HimmerFlowDeliveryAttributes.ContentState(
            completedFloors: 7,
            remainingFloors: 8,
            currentItemName: "Bath Mats",
            nextCarryGroupTitle: "Restart center stack",
            statusText: "Paused at 7/15 floors",
            targetTime: Calendar.current.date(byAdding: .minute, value: 90, to: .now),
            lastUpdated: .now,
            isActiveSession: false
        )
    }

    static var overtimePreview: HimmerFlowDeliveryAttributes.ContentState {
        var state = HimmerFlowDeliveryAttributes.ContentState(
            completedFloors: 13,
            remainingFloors: 2,
            currentItemName: "King Sheets",
            nextCarryGroupTitle: "North hallway final",
            statusText: "13/15 — overtime",
            targetTime: Calendar.current.date(byAdding: .minute, value: -9, to: .now),
            lastUpdated: .now,
            isActiveSession: true
        )
        state.currentItemNames = ["King Sheets", "King Covers"]
        return state
    }
}

struct HimmerFlowLiveActivityPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            LiveActivityContent(attributes: .diamondPreview, state: .activePreview)
                .previewDisplayName("Diamond Active")
            LiveActivityContent(attributes: .diamondPreview, state: .nearTargetPreview)
                .previewDisplayName("Near Target")
            LiveActivityContent(attributes: .diamondPreview, state: .overtimePreview)
                .previewDisplayName("Overtime")
            LiveActivityContent(attributes: .diamondPreview, state: .pausedPreview)
                .previewDisplayName("Paused")
            LiveActivityContent(attributes: .lagoonPreview, state: .completedPreview)
                .previewDisplayName("Completed Shift")
        }
        .previewLayout(.sizeThatFits)
    }
}
