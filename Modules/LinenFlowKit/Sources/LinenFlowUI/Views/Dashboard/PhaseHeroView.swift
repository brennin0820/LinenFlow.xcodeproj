import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct PhaseHeroView: View {
    public let phase: ShiftTimelinePhase
    public let nextActionLabel: String
    public let nextActionTime: Date
    public let clockInTime: Date?
    public let shiftName: String?
    public let now: Date
    public let isOffToday: Bool

    public init(
        phase: ShiftTimelinePhase,
        nextActionLabel: String,
        nextActionTime: Date,
        clockInTime: Date? = nil,
        shiftName: String? = nil,
        now: Date = .now,
        isOffToday: Bool = false
    ) {
        self.phase = phase
        self.nextActionLabel = nextActionLabel
        self.nextActionTime = nextActionTime
        self.clockInTime = clockInTime
        self.shiftName = shiftName
        self.now = now
        self.isOffToday = isOffToday
    }

    @ScaledMetric(relativeTo: .largeTitle) private var heroIconSize: CGFloat = 28
    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize: CGFloat = 52
    @ScaledMetric(relativeTo: .title) private var phaseTitleSize: CGFloat = 22

    public var body: some View {
        if isOffToday {
            OffTodayHeroView()
        } else {
            activeHero
        }
    }

    private var activeHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(phase.statusEmoji)
                    .font(.system(size: heroIconSize))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.displayName)
                        .font(.system(size: phaseTitleSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(HimmerFlowColors.secondaryText)
                        .accessibilityAddTraits(.isHeader)

                    if let shiftName {
                        Text(shiftName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(HimmerFlowColors.mutedText)
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(nextActionLabel)
                    .font(.system(size: countdownSize, weight: .bold, design: .rounded))
                    .foregroundStyle(HimmerFlowColors.heroText)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(nextActionLabel), next action")

                if nextActionTime > now {
                    Text(nextActionTime, style: .timer)
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(HimmerFlowColors.accent)
                        .accessibilityLabel("Countdown to \(nextActionTime.formatted(date: .omitted, time: .shortened))")
                }
            }

            if let clockInTime {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HimmerFlowColors.mutedText)
                    Text("Clock in \(HimmerFlowDateFormatting.timeString(clockInTime))")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(HimmerFlowColors.mutedText)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(HimmerFlowColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HimmerFlowColors.border, lineWidth: 1)
        )
    }
}

public struct OffTodayHeroView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 40

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Off today")
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                .foregroundStyle(HimmerFlowColors.heroText)
                .accessibilityAddTraits(.isHeader)

            Text("No shift is scheduled for today or tomorrow. Rest up — add a shift pattern when your schedule changes.")
                .font(.body)
                .foregroundStyle(HimmerFlowColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(HimmerFlowColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HimmerFlowColors.border, lineWidth: 1)
        )
    }
}

public enum HimmerFlowColors {
    public static let background = Color(red: 0.05, green: 0.05, blue: 0.07)
    public static let surface = Color(red: 0.10, green: 0.10, blue: 0.12)
    public static let heroText = Color.white
    public static let secondaryText = Color.white.opacity(0.82)
    public static let mutedText = Color.white.opacity(0.52)
    public static let accent = Color(red: 0.35, green: 0.78, blue: 1.0)
    public static let border = Color.white.opacity(0.10)
    public static let ctaFill = Color(red: 0.20, green: 0.55, blue: 0.95)
}
