import Foundation
import SwiftData

@Model
final class ShiftPlannerSettings {
    var sleepDurationMinutes: Int
    var getReadyDurationMinutes: Int
    var walkToCarMinutes: Int
    var commuteDurationMinutes: Int
    var parkingWalkMinutes: Int
    var walkInMinutes: Int
    var arrivalBufferMinutes: Int
    var preSleepWindDownMinutes: Int
    var beDownMinutesAfterShift: Int
    var monitoringTierRaw: String
    var hasCompletedOnboarding: Bool
    @Relationship(deleteRule: .nullify) var homeLocation: SavedLocation?

    enum MonitoringTier: String, Codable, CaseIterable, Sendable {
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

    var monitoringTier: MonitoringTier {
        get { MonitoringTier(rawValue: monitoringTierRaw) ?? .smart }
        set { monitoringTierRaw = newValue.rawValue }
    }

    init(
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
        homeLocation: SavedLocation? = nil,
        hasCompletedOnboarding: Bool = false
    ) {
        self.sleepDurationMinutes = sleepDurationMinutes
        self.getReadyDurationMinutes = getReadyDurationMinutes
        self.walkToCarMinutes = walkToCarMinutes
        self.commuteDurationMinutes = commuteDurationMinutes
        self.parkingWalkMinutes = parkingWalkMinutes
        self.walkInMinutes = walkInMinutes
        self.arrivalBufferMinutes = arrivalBufferMinutes
        self.preSleepWindDownMinutes = preSleepWindDownMinutes
        self.beDownMinutesAfterShift = beDownMinutesAfterShift
        self.monitoringTierRaw = monitoringTier.rawValue
        self.homeLocation = homeLocation
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
