import WidgetKit
import SwiftUI

// MARK: - Timeline types

struct ShiftStatusEntry: TimelineEntry {
    let date: Date
    let state: WidgetState
}

struct ShiftStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftStatusEntry {
        ShiftStatusEntry(date: .now, state: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftStatusEntry) -> Void) {
        completion(ShiftStatusEntry(date: .now, state: readWidgetState()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftStatusEntry>) -> Void) {
        let state = readWidgetState()
        let entry = ShiftStatusEntry(date: .now, state: state)
        let refresh = Calendar.current.date(byAdding: .minute, value: 5, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - Widget

struct ShiftStatusWidget: Widget {
    let kind = "ShiftStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShiftStatusProvider()) { entry in
            ShiftStatusWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Shift Status")
        .description("Track delivery progress and time remaining.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - View

struct ShiftStatusWidgetView: View {
    let entry: ShiftStatusEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: mediumView
        default: smallView
        }
    }

    // MARK: Small

    private var smallView: some View {
        let state = entry.state
        return ZStack {
            Color.black
            VStack(alignment: .leading, spacing: 0) {
                towerRow(state)
                Spacer()
                floorArc(state, size: 72, lineWidth: 6)
                    .frame(maxWidth: .infinity)
                Spacer()
                bottomRow(state)
            }
            .padding(12)
        }
    }

    // MARK: Medium

    private var mediumView: some View {
        let state = entry.state
        return ZStack {
            Color.black
            HStack(spacing: 14) {
                VStack(spacing: 4) {
                    floorArc(state, size: 76, lineWidth: 7)
                    Text(state.towerName)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(state.accentColor)
                        .lineLimit(1)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        if state.isDeliveryActive {
                            Circle().fill(.green).frame(width: 6, height: 6)
                        }
                        Text(state.isDeliveryActive ? "Active" : "Not Started")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.timeText)
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                        Text("to target")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.40))
                    }
                    pacePill(state)
                    if let focus = state.currentItemFocus {
                        Text(focus)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                    } else if let trip = state.nextTripTitle {
                        Text(trip)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
    }

    // MARK: Subviews

    @ViewBuilder
    private func towerRow(_ state: WidgetState) -> some View {
        HStack(spacing: 5) {
            Circle().fill(state.accentColor).frame(width: 7, height: 7)
            Text(state.towerName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer()
            if state.isDeliveryActive {
                Circle().fill(.green).frame(width: 5, height: 5)
            }
        }
    }

    @ViewBuilder
    private func floorArc(_ state: WidgetState, size: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            FloorProgressArc(
                fraction: state.progressFraction,
                accentColor: state.accentColor,
                lineWidth: lineWidth
            )
            VStack(spacing: 0) {
                Text("\(state.completedFloors)")
                    .font(.system(size: size * 0.30, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text("/ \(state.totalFloors)")
                    .font(.system(size: size * 0.14, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func bottomRow(_ state: WidgetState) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(state.timeText)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                Text("remaining")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            pacePill(state)
        }
    }

    @ViewBuilder
    private func pacePill(_ state: WidgetState) -> some View {
        Text(state.paceStatusLabel)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(paceColor(state.paceStatusLabel))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(paceColor(state.paceStatusLabel).opacity(0.15), in: Capsule())
    }
}
