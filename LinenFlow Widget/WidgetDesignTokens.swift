import SwiftUI

enum WidgetDesignTokens {
    enum Typography {
        static let badge = Font.caption2.weight(.heavy)
        static let countdown = Font.caption.weight(.heavy).monospacedDigit()
        static let floorCount = Font.title3.weight(.heavy).monospacedDigit()
        static let compactFloorCount = Font.caption2.weight(.heavy).monospacedDigit()
        static let item = Font.caption.weight(.semibold)
    }

    enum ColorToken {
        static let nightBase = Color(red: 0.035, green: 0.043, blue: 0.052)
        static let nightElevated = Color(red: 0.060, green: 0.070, blue: 0.082)
        static let nightDeep = Color(red: 0.028, green: 0.033, blue: 0.040)
        static let inactive = Color(red: 0.42, green: 0.46, blue: 0.50)
        static let ready = Color(red: 0.62, green: 0.67, blue: 0.72)
        static let paused = Color(red: 0.78, green: 0.58, blue: 0.32)
        static let finishing = Color(red: 0.94, green: 0.58, blue: 0.23)
        static let urgent = Color(red: 0.93, green: 0.31, blue: 0.28)
        static let overtime = Color(red: 1.00, green: 0.18, blue: 0.12)
        static let complete = Color.green
        static let demo = Color.indigo
        static let defaultAccent = Color.teal
    }

    enum Radius {
        static let compact: CGFloat = 8
        static let surface: CGFloat = 12
    }

    enum Spacing {
        static let hairline: CGFloat = 3
        static let compact: CGFloat = 6
        static let standard: CGFloat = 10
        static let content: CGFloat = 14
    }

    enum Opacity {
        static let primaryText: Double = 0.92
        static let secondaryText: Double = 0.62
        static let tertiaryText: Double = 0.46
        static let surface: Double = 0.065
        static let stroke: Double = 0.12
        static let badge: Double = 0.34
    }

    enum Layout {
        static let progressHeight: CGFloat = 6
        static let compactProgressHeight: CGFloat = 4
        static let ringLineWidth: CGFloat = 8
        static let smallRingSize: CGFloat = 78
    }

    static func towerAccent(_ hex: String?) -> Color {
        Color(hex: hex) ?? ColorToken.defaultAccent
    }

    static func statusColor(for snapshot: OperationalShiftSnapshot, towerColorHex: String?) -> Color {
        if snapshot.isDemoDay { return ColorToken.demo }
        switch snapshot.semanticState {
        case .noActiveDelivery:
            return ColorToken.inactive
        case .ready:
            return ColorToken.ready
        case .paused:
            return ColorToken.paused
        case .complete:
            return ColorToken.complete
        case .overtime:
            return ColorToken.overtime
        case .finishing:
            return ColorToken.urgent
        case .finalFloors:
            return ColorToken.finishing
        default:
            return progressTint(for: snapshot.urgencyLevel, towerColorHex: towerColorHex)
        }
    }

    static func progressTint(for urgency: CountdownUrgencyLevel, towerColorHex: String?) -> Color {
        switch urgency {
        case .inactive:
            return ColorToken.inactive
        case .complete:
            return ColorToken.complete
        case .critical:
            return ColorToken.overtime
        case .urgent:
            return ColorToken.urgent
        case .warm:
            return ColorToken.finishing
        case .calm:
            return towerAccent(towerColorHex)
        }
    }

    static func badgeStyle(for snapshot: OperationalShiftSnapshot, towerColorHex: String?) -> (text: String, color: Color) {
        (snapshot.semanticState.displayName, statusColor(for: snapshot, towerColorHex: towerColorHex))
    }

    static func compactTowerName(_ towerName: String) -> String {
        OperationalShiftStateEngine.compactTowerName(towerName)
    }

    static func surfaceGradient(accent: Color, active: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                ColorToken.nightBase,
                ColorToken.nightElevated,
                ColorToken.nightDeep,
                accent.opacity(0.12),
                active.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func countdownUrgency(targetTime: Date?, isComplete: Bool, hasTower: Bool) -> CountdownUrgencyLevel {
        OperationalShiftStateEngine.countdownUrgency(
            targetTime: targetTime,
            isComplete: isComplete,
            hasTower: hasTower
        )
    }
}
