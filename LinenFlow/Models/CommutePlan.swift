import Foundation

enum WazeDestinationMode: String, Codable, CaseIterable {
    case favWork = "favWork"
    case favHome = "favHome"
    case searchAddress = "searchAddress"
    case coordinates = "coordinates"

    var displayName: String {
        switch self {
        case .favWork: return "Maps Favorite: Work"
        case .favHome: return "Maps Favorite: Home"
        case .searchAddress: return "Search Address"
        case .coordinates: return "Coordinates"
        }
    }
}

struct CommutePlan: Codable {
    var id: UUID = UUID()
    // Addresses — stored on-device only, never exported or logged
    var homeLabel: String = "Home"
    var homeAddress: String = ""
    var workLabel: String = "Work"
    var workAddress: String = ""
    // Target arrival time components
    var targetArrivalHour: Int = 22
    var targetArrivalMinute: Int = 45
    // Planning minutes
    var manualEstimatedDriveMinutes: Int = 30
    var walkToCarMinutes: Int = 5
    var safetyBufferMinutes: Int = 15
    var prepMinutes: Int = 40
    var leaveSoonAlertMinutes: Int = 10
    var shiftSoonAlertMinutes: Int = 10
    var checklistReminderBeforeWalkToCarMinutes: Int = 5
    // Waze settings
    var wazeDestinationMode: WazeDestinationMode = .searchAddress
    var wazeSearchQuery: String = ""
    var wazeLatitude: Double = 21.2830
    var wazeLongitude: Double = -157.8360
}
