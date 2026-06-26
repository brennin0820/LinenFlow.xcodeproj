import Foundation

public enum WazeDestinationMode: String, Codable, CaseIterable {
    case favWork = "favWork"
    case favHome = "favHome"
    case searchAddress = "searchAddress"
    case coordinates = "coordinates"

    public var displayName: String {
        switch self {
        case .favWork: return "Maps Favorite: Work"
        case .favHome: return "Maps Favorite: Home"
        case .searchAddress: return "Search Address"
        case .coordinates: return "Coordinates"
        }
    }
}

public struct CommutePlan: Codable {
    public var id: UUID = UUID()
    // Addresses — stored on-device only, never exported or logged
    public var homeLabel: String = "Home"
    public var homeAddress: String = ""
    public var workLabel: String = "Work"
    public var workAddress: String = ""
    // Target arrival time components
    public var targetArrivalHour: Int = 22
    public var targetArrivalMinute: Int = 45
    // Planning minutes
    public var manualEstimatedDriveMinutes: Int = 30
    public var walkToCarMinutes: Int = 5
    public var safetyBufferMinutes: Int = 15
    public var prepMinutes: Int = 40
    public var leaveSoonAlertMinutes: Int = 10
    public var shiftSoonAlertMinutes: Int = 10
    public var checklistReminderBeforeWalkToCarMinutes: Int = 5
    // Waze settings
    public var wazeDestinationMode: WazeDestinationMode = .searchAddress
    public var wazeSearchQuery: String = ""
    public var wazeLatitude: Double = 21.2830
    public var wazeLongitude: Double = -157.8360
}
