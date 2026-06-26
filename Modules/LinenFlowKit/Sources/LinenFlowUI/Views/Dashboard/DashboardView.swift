import SwiftUI
import LinenFlowCore
import LinenFlowEngine

@Observable
public final class ShiftDashboardViewModel {
    public var orchestrator: ShiftOrchestrator?
    public var now: Date = .now

    public var currentPhase: ShiftTimelinePhase {
        orchestrator?.currentPhase ?? .idle
    }

    public var isOffToday: Bool {
        orchestrator?.isOffToday ?? true
    }

    public var timeline: ShiftTimelineSnapshot? {
        orchestrator?.currentTimeline
    }

    public var activePatternName: String? {
        orchestrator?.activePattern?.name
    }

    public var degradationMessage: String? {
        orchestrator?.degradationMessage
    }

    public var heroPresentation: (label: String, time: Date) {
        guard let timeline else {
            return ("No shift scheduled", now)
        }
        if let next = timeline.nextTransition(after: now) {
            let label = "\(next.phase.displayName) in \(HimmerFlowDateFormatting.relativeHours(until: next.start, from: now))"
            return (label, next.start)
        }
        return (currentPhase.displayName, timeline.primaryAnchor)
    }

    public func primaryCTA() -> (title: String, systemImage: String) {
        switch currentPhase {
        case .idle:
            return ("Add Shift Pattern", "calendar.badge.plus")
        case .preSleep:
            return ("Start Wind Down", "moon.zzz.fill")
        case .sleep:
            return ("Set Alarm", "alarm.fill")
        case .wake:
            return ("I'm Awake", "sunrise.fill")
        case .getReady:
            return ("Getting Ready", "shower.fill")
        case .walkToCar:
            return ("Heading Out", "figure.walk")
        case .leave:
            return ("I'm Leaving", "car.fill")
        case .commute:
            return ("On My Way", "road.lanes")
        case .parking:
            return ("Parked", "parkingsign")
        case .walkIn:
            return ("Walking In", "figure.walk.arrival")
        case .arrival:
            return ("Almost There", "building.2.fill")
        case .shiftCountdown:
            return ("Start Shift", "clock.badge.checkmark.fill")
        case .shiftActive:
            return ("On Shift", "briefcase.fill")
        case .beDown:
            return ("Wind Down", "bed.double.fill")
        case .shiftEnd:
            return ("Shift Complete", "checkmark.circle.fill")
        }
    }

    public func performPrimaryCTA() async {
        guard let orchestrator else { return }
        if currentPhase.requiresAcknowledgement {
            await orchestrator.acknowledge(phase: currentPhase)
        } else {
            await orchestrator.reconcile(trigger: .timerTick)
        }
    }
}

public struct DashboardView: View {
    @Bindable public var viewModel: ShiftDashboardViewModel
    public var onManagePatterns: () -> Void = {}
    public var onOpenSettings: () -> Void = {}
    public var onPrimaryAction: (() -> Void)?

    @State private var selectedPhase: ShiftTimelinePhase?

    public init(
        viewModel: ShiftDashboardViewModel,
        onManagePatterns: @escaping () -> Void = {},
        onOpenSettings: @escaping () -> Void = {},
        onPrimaryAction: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onManagePatterns = onManagePatterns
        self.onOpenSettings = onOpenSettings
        self.onPrimaryAction = onPrimaryAction
    }

    /// Compatibility with `ShiftPlannerRootView` and orchestrator-first wiring.
    public init(orchestrator: ShiftOrchestrator, onPrimaryAction: @escaping () -> Void) {
        let model = ShiftDashboardViewModel()
        model.orchestrator = orchestrator
        self.init(viewModel: model, onPrimaryAction: onPrimaryAction)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                dateHeader

                if let message = viewModel.degradationMessage {
                    degradationBanner(message)
                }

                if viewModel.isOffToday {
                    OffTodayHeroView()
                    offTodayActions
                } else {
                    activeShiftContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 32)
        }
    }

    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.now.formatted(.dateTime.weekday(.wide)))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(HimmerFlowColors.heroText)
                Text(viewModel.now.formatted(.dateTime.month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(HimmerFlowColors.mutedText)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var activeShiftContent: some View {
        Group {
            let hero = viewModel.heroPresentation
            PhaseHeroView(
                phase: viewModel.currentPhase,
                nextActionLabel: hero.label,
                nextActionTime: hero.time,
                clockInTime: viewModel.timeline?.primaryAnchor,
                shiftName: viewModel.activePatternName,
                now: viewModel.now
            )

            primaryCTAButton

            if let timeline = viewModel.timeline {
                TimelineStrip(
                    timeline: timeline,
                    currentPhase: viewModel.currentPhase,
                    now: viewModel.now,
                    selectedPhase: $selectedPhase
                )
            }
        }
    }

    private var primaryCTAButton: some View {
        let cta = viewModel.primaryCTA()
        return Button {
            if let onPrimaryAction {
                onPrimaryAction()
            } else {
                Task { await viewModel.performPrimaryCTA() }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: cta.systemImage)
                    .font(.headline.weight(.semibold))
                Text(cta.title)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .foregroundStyle(.white)
            .background(HimmerFlowColors.ctaFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cta.title)
    }

    private var offTodayActions: some View {
        VStack(spacing: 12) {
            Button(action: onManagePatterns) {
                Label("Manage Shift Patterns", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .foregroundStyle(HimmerFlowColors.heroText)
                    .background(HimmerFlowColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(HimmerFlowColors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onOpenSettings) {
                Label("Duration Settings", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .foregroundStyle(HimmerFlowColors.secondaryText)
                    .background(HimmerFlowColors.surface.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func degradationBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "location.slash.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(HimmerFlowColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
