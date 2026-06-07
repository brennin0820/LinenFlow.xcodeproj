import SwiftUI

struct ShiftEventCountdownCard: View {
    let plan: WorkdayPlan

    private var accentColor: Color { towerAccentColor(plan.assignedTowerName) }

    private var events: [(label: String, icon: String, time: Date)] {[
        ("Get Ready",     "figure.stand",          plan.startGettingReadyTime),
        ("Leave Soon",    "bell.fill",              plan.leaveSoonTime),
        ("Check Items",   "checklist",              plan.checklistReminderTime),
        ("Walk to Car",   "figure.walk",            plan.walkToCarTime),
        ("Start Driving", "car.fill",               plan.startDrivingTime),
        ("Arrive",        "mappin.circle.fill",     plan.targetArrivalTime),
        ("Shift Starts",  "moon.stars.fill",        plan.shiftStartDateTime),
        ("Shift Ends",    "checkmark.circle.fill",  plan.shiftEndDateTime),
    ]}

    var body: some View {
        PremiumCard(accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(accentColor.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shift Countdown")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Live timers for every event")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                }

                Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let now = context.date
                    let nextIndex = events.firstIndex(where: { now < $0.time })
                    VStack(spacing: 0) {
                        ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                            ShiftEventRow(
                                label: event.label,
                                icon: event.icon,
                                time: event.time,
                                now: now,
                                isPast: now >= event.time,
                                isNext: index == nextIndex,
                                accentColor: accentColor
                            )
                            if index < events.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.055))
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct ShiftEventRow: View {
    let label: String
    let icon: String
    let time: Date
    let now: Date
    let isPast: Bool
    let isNext: Bool
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if isPast {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green.opacity(0.65))
                } else {
                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isNext ? accentColor : .white.opacity(0.65))
                }
            }
            .frame(width: 28, height: 28)
            .background(
                isPast   ? Color.white.opacity(0.04)
                : isNext ? accentColor.opacity(0.18)
                         : Color.white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.subheadline.weight(isNext ? .semibold : .regular))
                    .foregroundStyle(isPast ? .white.opacity(0.28) : isNext ? .white : .white.opacity(0.78))
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(isPast ? .white.opacity(0.15) : .white.opacity(0.42))
            }

            Spacer()

            Text(countdownLabel)
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(
                    isPast   ? .white.opacity(0.2)
                    : isNext ? accentColor
                             : .white.opacity(0.52)
                )
                .contentTransition(.numericText())
        }
        .padding(.vertical, 10)
        .padding(.horizontal, isNext ? 10 : 2)
        .background(
            isNext ? accentColor.opacity(0.07) : .clear,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay(
            Group {
                if isNext {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accentColor.opacity(0.28), lineWidth: 1)
                }
            }
        )
        .animation(.easeInOut(duration: 0.35), value: isPast)
        .animation(.easeInOut(duration: 0.35), value: isNext)
    }

    private var countdownLabel: String {
        if isPast { return "Done" }
        let secs = Int(time.timeIntervalSince(now))
        guard secs > 0 else { return "Now" }
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }
}

private func towerAccentColor(_ name: String) -> Color {
    switch name.lowercased() {
    case "rainbow":                    return Color(red: 0.0,   green: 0.624, blue: 0.859)
    case "ali'i", "alii":              return Color(red: 0.055, green: 0.561, blue: 0.427)
    case "tapa":                       return Color(red: 0.788, green: 0.416, blue: 0.322)
    case "diamond":                    return Color(red: 0.435, green: 0.486, blue: 0.522)
    case "kalia":                      return Color(red: 0.482, green: 0.682, blue: 0.498)
    case "lagoon":                     return Color(red: 0.0,   green: 0.686, blue: 0.780)
    case "grand waikikian", "gw":      return Color(red: 0.247, green: 0.306, blue: 0.549)
    case "grand islander", "gi":       return Color(red: 0.851, green: 0.604, blue: 0.169)
    default:                           return .blue
    }
}
