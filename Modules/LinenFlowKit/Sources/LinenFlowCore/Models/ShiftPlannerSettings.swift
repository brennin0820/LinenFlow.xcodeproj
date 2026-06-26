import Foundation
import SwiftData

@Model
public final class ShiftPlannerSettings {
    /// The single hard anchor: time the user must be clocked in (hour/minute only; no Calendar).
    public var clockInHour: Int
    public var clockInMinute: Int

    public var sleepDurationMinutes: Int
    public var getReadyDurationMinutes: Int
    public var walkToCarMinutes: Int
    public var commuteDurationMinutes: Int
    public var parkingWalkMinutes: Int
    public var walkInMinutes: Int
    public var arrivalBufferMinutes: Int
    public var preSleepWindDownMinutes: Int
    public var beDownMinutesAfterShift: Int
    public var monitoringTier: MonitoringTier
    public var hasCompletedOnboarding: Bool
    public var homeLocation: SavedLocation?

    public enum MonitoringTier: String, Codable, CaseIterable {
        case manual
        case smart
        case activeCommute

        public var displayName: String {
            switch self {
            case .manual: return "Manual"
            case .smart: return "Smart"
            case .activeCommute: return "Active Commute"
            }
        }
    }

    public init(
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
