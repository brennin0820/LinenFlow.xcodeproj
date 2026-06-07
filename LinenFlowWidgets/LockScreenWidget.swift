import WidgetKit
import SwiftUI

struct LockScreenWidget: Widget {
    let kind = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShiftStatusProvider()) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("HimmerFlow")
        .description("Floor progress on lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWidgetView: View {
    let entry: ShiftStatusEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: circularView
        case .accessoryRectangular: rectangularView
        default: inlineView
        }
    }

    private var circularView: some View {
        let state = entry.state
        return ZStack {
            FloorProgressArc(fraction: state.progressFraction, accentColor: .white, lineWidth: 3)
            VStack(spacing: 0) {
                Text("\(state.completedFloors)")
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text("\(state.totalFloors)")
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    private var rectangularView: some View {
        let state = entry.state
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(state.towerName)
                    .font(.caption.weight(.bold))
                Spacer()
                Text(state.timeText)
                    .font(.caption.weight(.bold).monospacedDigit())
            }
            ProgressView(value: state.progressFraction)
                .progressViewStyle(.linear)
                .tint(.white)
            HStack {
                Text("\(state.remainingFloors) floors left")
                    .font(.caption2.weight(.semibold))
                Spacer()
                Text(state.paceStatusLabel)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.70))
        }
        .foregroundStyle(.white)
    }

    private var inlineView: some View {
        let state = entry.state
        return Label {
            Text("\(state.towerName) \(state.completedFloors)/\(state.totalFloors) · \(state.timeText)")
        } icon: {
            Image(systemName: "figure.walk")
        }
    }
}
