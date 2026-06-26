import Foundation

public struct WorkdayPlan {
    public var id: UUID = UUID()
    public var weekday: Int
    public var shiftStartDateTime: Date
    public var shiftEndDateTime: Date
    public var assignedTowerName: String
    public var targetArrivalTime: Date
    public var startDrivingTime: Date
    public var walkToCarTime: Date
    public var bufferStartTime: Date
    public var startGettingReadyTime: Date
    public var leaveSoonTime: Date
    public var checklistReminderTime: Date
    public var shiftSoonTime: Date
    public var warnings: [String] = []

    public var weekdayName: String {
        Calendar.current.weekdaySymbols[weekday - 1]
    }

    // MARK: - Phase

    public enum Phase: Equatable {
        case earlyPrep
        case gettingReady
        case leaveSoon
        case checklistTime
        case walkingToCar
        case driving
        case arrivingSoon
        case onShift
        case done

        public var label: String {
            switch self {
            case .earlyPrep:      return "Pre-Shift"
            case .gettingReady:   return "Get Ready"
            case .leaveSoon:      return "Leave Soon"
            case .checklistTime:  return "Check Items"
            case .walkingToCar:   return "Walk to Car"
            case .driving:        return "Drive Now"
            case .arrivingSoon:   return "Almost There"
            case .onShift:        return "On Shift"
            case .done:           return "Shift Done"
            }
        }

        public var systemImage: String {
            switch self {
            case .earlyPrep:     return "clock"
            case .gettingReady:  return "figure.stand"
            case .leaveSoon:     return "bell.fill"
            case .checklistTime: return "checklist"
            case .walkingToCar:  return "figure.walk"
            case .driving:       return "car.fill"
            case .arrivingSoon:  return "mappin.circle.fill"
            case .onShift:       return "moon.stars.fill"
            case .done:          return "checkmark.circle.fill"
            }
        }

        public var isUrgent: Bool {
            switch self {
            case .leaveSoon, .checklistTime, .walkingToCar, .driving: return true
            default: return false
            }
        }
    }

    public func phase(at date: Date = .now) -> Phase {
        if date < startGettingReadyTime { return .earlyPrep }
        if date < leaveSoonTime         { return .gettingReady }
        if date < checklistReminderTime { return .leaveSoon }
        if date < walkToCarTime         { return .checklistTime }
        if date < startDrivingTime      { return .walkingToCar }
        if date < targetArrivalTime     { return .driving }
        if date < shiftStartDateTime    { return .arrivingSoon }
        if date < shiftEndDateTime      { return .onShift }
        return .done
    }

    public func nextKeyEvent(at date: Date = .now) -> (label: String, time: Date)? {
        switch phase(at: date) {
        case .earlyPrep:     return ("Get Ready", startGettingReadyTime)
        case .gettingReady:  return ("Leave Soon", leaveSoonTime)
        case .leaveSoon:     return ("Check Items", checklistReminderTime)
        case .checklistTime: return ("Walk to Car", walkToCarTime)
        case .walkingToCar:  return ("Start Driving", startDrivingTime)
        case .driving:       return ("Arrive", targetArrivalTime)
        case .arrivingSoon:  return ("Shift Starts", shiftStartDateTime)
        case .onShift:       return ("Shift Ends", shiftEndDateTime)
        case .done:          return nil
        }
    }

    public static func countdownString(from: Date, to: Date) -> String {
        let interval = to.timeIntervalSince(from)
        guard interval > 0 else { return "Now" }
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let mins  = totalMinutes % 60
        if hours > 0 { return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h" }
        return "\(mins)m"
    }
}
