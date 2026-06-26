import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct TimelineStrip: View {
    public let timeline: ShiftTimelineSnapshot?
    public let currentPhase: ShiftTimelinePhase
    public let now: Date
    @Binding public var selectedPhase: ShiftTimelinePhase?

    public init(
        timeline: ShiftTimelineSnapshot?,
        currentPhase: ShiftTimelinePhase,
        now: Date,
        selectedPhase: Binding<ShiftTimelinePhase?> = .constant(nil)
    ) {
        self.timeline = timeline
        self.currentPhase = currentPhase
        self.now = now
        self._selectedPhase = selectedPhase
    }

    public var body: some View {
        if let timeline {
            timelineContent(timeline)
        }
    }

    private func timelineContent(_ timeline: ShiftTimelineSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline.weight(.semibold))
                .foregroundStyle(HimmerFlowColors.secondaryText)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(displayPhases(in: timeline), id: \.phase) { window in
                        TimelinePhaseChip(
                            window: window,
                            isCurrent: window.phase == currentPhase,
                            isPast: window.end < now && window.phase != currentPhase,
                            isSelected: selectedPhase == window.phase
                        ) {
                            withAnimation(.snappy(duration: 0.2)) {
                                selectedPhase = selectedPhase == window.phase ? nil : window.phase
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            if let selected = selectedPhase, let detail = timeline.window(for: selected) {
                TimelinePhaseDetail(window: detail, now: now)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.snappy(duration: 0.2), value: selectedPhase)
    }

    private func displayPhases(in timeline: ShiftTimelineSnapshot) -> [ShiftTimelineSnapshot.PhaseWindow] {
        timeline.phases.filter { $0.phase != .idle }
    }
}

private struct TimelinePhaseChip: View {
    public let window: ShiftTimelineSnapshot.PhaseWindow
    public let isCurrent: Bool
    public let isPast: Bool
    public let isSelected: Bool
    public let onTap: () -> Void

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(window.phase.statusEmoji)
                    .font(.title3)
                Text(window.phase.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(timeLabel)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(HimmerFlowColors.mutedText)
            }
            .foregroundStyle(isCurrent ? HimmerFlowColors.heroText : HimmerFlowColors.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(chipBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: isCurrent || isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(window.phase.displayName), \(timeLabel)")
        .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
    }

    private var timeLabel: String {
        if window.isPointEvent {
            return HimmerFlowDateFormatting.timeString(window.start)
        }
        return "\(HimmerFlowDateFormatting.timeString(window.start)) – \(HimmerFlowDateFormatting.timeString(window.end))"
    }

    private var chipBackground: Color {
        if isCurrent { return HimmerFlowColors.accent.opacity(0.18) }
        if isPast { return HimmerFlowColors.surface.opacity(0.6) }
        return HimmerFlowColors.surface
    }

    private var borderColor: Color {
        if isCurrent || isSelected { return HimmerFlowColors.accent }
        return HimmerFlowColors.border
    }
}

private struct TimelinePhaseDetail: View {
    public let window: ShiftTimelineSnapshot.PhaseWindow
    public let now: Date

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(window.phase.displayName)
                    .font(.subheadline.weight(.bold))
                Spacer()
                if window.phase.requiresAcknowledgement {
                    Text("Tap to confirm")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(HimmerFlowColors.accent)
                }
            }

            if window.isPointEvent {
                detailRow("At", HimmerFlowDateFormatting.timeString(window.start))
            } else {
                detailRow("Start", HimmerFlowDateFormatting.timeString(window.start))
                detailRow("End", HimmerFlowDateFormatting.timeString(window.end))
            }

            if window.start > now {
                detailRow("In", HimmerFlowDateFormatting.relativeHours(until: window.start, from: now))
            }
        }
        .font(.footnote)
        .foregroundStyle(HimmerFlowColors.secondaryText)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HimmerFlowColors.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(HimmerFlowColors.mutedText)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }
}
