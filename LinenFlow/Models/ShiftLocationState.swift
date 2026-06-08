import CoreLocation
import Foundation

struct ShiftLocationState: Codable, Equatable, Sendable {
    var locationAuthStatusRaw: Int32 = CLAuthorizationStatus.notDetermined.rawValue
    var accuracyAuthorizationRaw: Int = CLAccuracyAuthorization.fullAccuracy.rawValue
    var isInsideHomeRegion: Bool?
    var isInsideWorkRegion: Bool?
    var homeExitTimestamp: Date?
    var workEntryTimestamp: Date?
    var hasConfirmedDeparture: Bool = false
    var hasConfirmedArrival: Bool = false

    var locationAuthStatus: CLAuthorizationStatus {
        get { CLAuthorizationStatus(rawValue: locationAuthStatusRaw) ?? .notDetermined }
        set { locationAuthStatusRaw = newValue.rawValue }
    }

    var accuracyAuthorization: CLAccuracyAuthorization {
        get { CLAccuracyAuthorization(rawValue: accuracyAuthorizationRaw) ?? .fullAccuracy }
        set { accuracyAuthorizationRaw = newValue.rawValue }
    }

    mutating func resetForNewShift() {
        homeExitTimestamp = nil
        workEntryTimestamp = nil
        hasConfirmedDeparture = false
        hasConfirmedArrival = false
    }
}
