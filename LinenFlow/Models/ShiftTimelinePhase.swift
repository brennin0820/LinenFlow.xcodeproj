import Foundation

enum ShiftTimelinePhase: Int, Codable, CaseIterable, Comparable, Hashable, Sendable {
    case idle = 0
    case preSleep = 1
    case sleep = 2
    case wake = 3
    case getReady = 4
    case walkToCar = 5
    case leave = 6
    case commute = 7
    case parking = 8
    case walkIn = 9
    case arrival = 10
    case shiftCountdown = 11
    case shiftActive = 12
    case beDown = 13
    case shiftEnd = 14

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var displayName: String {
        switch self {
        case .idle: return "Off"
        case .preSleep: return "Wind Down"
        case .sleep: return "Sleep"
        case .wake: return "Wake Up"
        case .getReady: return "Get Ready"
        case .walkToCar: return "Walk to Car"
        case .leave: return "Leave Now"
        case .commute: return "Commute"
        case .parking: return "Parking"
        case .walkIn: return "Walk In"
        case .arrival: return "Arrival"
        case .shiftCountdown: return "Almost Time"
        case .shiftActive: return "On Shift"
        case .beDown: return "Wind Down"
        case .shiftEnd: return "Shift Complete"
        }
    }

    var statusEmoji: String {
        switch self {
        case .idle: return "😴"
        case .preSleep: return "🌙"
        case .sleep: return "💤"
        case .wake: return "⏰"
        case .getReady: return "🚿"
        case .walkToCar: return "🚶"
        case .leave: return "🚗"
        case .commute: return "🛣️"
        case .parking: return "🅿️"
        case .walkIn: return "🚶‍♂️"
        case .arrival: return "🏢"
        case .shiftCountdown: return "⏳"
        case .shiftActive: return "💼"
        case .beDown: return "🌙"
        case .shiftEnd: return "✅"
        }
    }

    var requiresAcknowledgement: Bool {
        switch self {
        case .wake, .leave: return true
        default: return false
        }
    }
}
