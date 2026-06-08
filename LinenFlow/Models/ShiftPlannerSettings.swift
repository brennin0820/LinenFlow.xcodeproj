import Foundation
import SwiftData

@Model
final class ShiftPlannerSettings {
    /// The single hard anchor: time the user must be clocked in (hour/minute only; no Calendar).
    var clockInHour: Int
    var clockInMinute: Int

    var sleepDurationMinutes: Int
    var getReadyDurationMinutes: Int
    var walkToCarMinutes: Int
    var commuteDurationMinutes: Int
    var parkingWalkMinutes: Int
    var walkInMinutes: Int
    var arrivalBufferMinutes: Int
    var preSleepWindDownMinutes: Int
    var beDownMinutesAfterShift: Int
    var monitoringTier: MonitoringTier
    var hasCompletedOnboarding: Bool
    var homeLocation: SavedLocation?

    enum MonitoringTier: String, Codable, CaseIterable {
        case manual
        case smart
        case activeCommute

        var displayName: String {
            switch self {
            case .manual: return "Manual"
            case .smart: return "Smart"
            case .activeCommute: return "Active Commute"
            }
        }
    }

    init(
        clockInHour: Int = 6,
        clockInMinute: Int = 0,
        sleepDurationMinutes: Int = 480,
        getReadyDurationMinutes: Int = 45,
        walkToCarMinutes: Int = 5,
        commuteDurationMinutes: Int = 30,
        parkingWalkMinutes: Int = 10,
        walkInMinutes: Int = 5,
        arrivalBufferMinutes: Int = 15,
        preSleepWindDownMinutes: Int = 30,
        beDownMinutesAfterShift: Int = 60,
        monitoringTier: MonitoringTier = .smart,
        hasCompletedOnboarding: Bool = false,
        homeLocation: SavedLocation? = nil
    ) {
        self.clockInHour = clockInHour
        self.clockInMinute = clockInMinute
        self.sleepDurationMinutes = sleepDurationMinutes
        self.getReadyDurationMinutes = getReadyDurationMinutes
        self.walkToCarMinutes = walkToCarMinutes
        self.commuteDurationMinutes = commuteDurationMinutes
        self.parkingWalkMinutes = parkingWalkMinutes
        self.walkInMinutes = walkInMinutes
        self.arrivalBufferMinutes = arrivalBufferMinutes
        self.preSleepWindDownMinutes = preSleepWindDownMinutes
        self.beDownMinutesAfterShift = beDownMinutesAfterShift
        self.monitoringTier = monitoringTier
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.homeLocation = homeLocation
    }
}
