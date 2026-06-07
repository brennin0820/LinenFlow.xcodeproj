import SwiftUI
import WidgetKit

// MARK: - Color hex (widget extension copy — main app has this in TowerAccentStrip.swift)

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - WidgetState display helpers

extension WidgetState {
    var accentColor: Color {
        Color(hex: towerAccentHex) ?? .blue
    }

    var timeText: String {
        if hoursToTarget > 0 { return "\(hoursToTarget)h \(minutesRemainder)m" }
        return "\(minutesToTarget)m"
    }
}

// MARK: - Floor progress arc

struct FloorProgressArc: View {
    let fraction: Double
    let accentColor: Color
    var lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Pace status color

func paceColor(_ label: String) -> Color {
    let lower = label.lowercased()
    if lower.contains("behind") { return .orange }
    if lower.contains("ahead") { return .cyan }
    if lower.contains("not") { return .white.opacity(0.50) }
    return .green
}

// MARK: - App Group state read

func readWidgetState() -> WidgetState {
    let legacyKeys = ["linenflow.widgetState", "com.linenflow.widgetState"]
    let groupIDs = ["group.com.himmerflow.shared", "group.com.linenflow.shared"]

    for groupID in groupIDs {
        guard let defaults = UserDefaults(suiteName: groupID) else { continue }
        for key in ["himmerflow.widgetState"] + legacyKeys {
            guard let data = defaults.data(forKey: key),
                  let state = try? JSONDecoder().decode(WidgetState.self, from: data) else { continue }
            return state
        }
    }

    return .empty
}
