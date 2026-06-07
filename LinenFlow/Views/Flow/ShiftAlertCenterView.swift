import SwiftUI

struct ShiftAlertCenterView: View {
    let session: ShiftSession
    let alertText: String
    let now: Date

    private var minutesToTarget: Int {
        max(0, Int(session.targetDownTime.timeIntervalSince(now) / 60))
    }

    private var statusColor: Color {
        switch session.paceStatus {
        case .notStarted: return .white.opacity(0.65)
        case .ahead: return .green
        case .onPace: return .blue
        case .behind: return .orange
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            stickyStatusBanner

            PremiumCard(accentColor: statusColor) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Countdown")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.56))
                            Text(durationText(minutes: minutesToTarget))
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.62)
                                .contentTransition(.numericText())
                            Text("Target down: \(session.targetDownTime.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                        }

                        Spacer()

                        Text(session.paceStatus.displayName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.16), in: Capsule())
                    }

                    HStack(spacing: 8) {
                        MetricTile(label: "Finish", value: estimatedFinishText, secondary: "predicted", tint: statusColor)
                        MetricTile(label: "Left", value: "\(session.remainingFloors.count)", secondary: "floors", tint: .green)
                    }

                    if session.remainingBundles > 0 {
                        HStack(spacing: 8) {
                            MetricTile(label: "Bundles", value: "\(session.remainingBundles)", secondary: "remaining", tint: .indigo)
                            MetricTile(label: "Avg", value: averageText, secondary: "min/floor", tint: .cyan)
                        }
                    } else {
                        MetricTile(label: "Average", value: averageText, secondary: "min/floor", tint: .cyan)
                    }
                }
            }
        }
    }

    private var stickyStatusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: session.paceStatus == .behind ? "exclamationmark.triangle.fill" : "bolt.circle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(statusColor)
            Text(alertText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(statusColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(statusColor.opacity(0.22), lineWidth: 1)
        )
    }

    private var estimatedFinishText: String {
        session.estimatedCompletionTime?.formatted(date: .omitted, time: .shortened) ?? "--"
    }

    private var averageText: String {
        String(format: "%.1f", session.averageFloorCompletionMinutes)
    }

    private func durationText(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours):" + String(format: "%02d", mins)
        }
        return "\(mins)m"
    }
}
