import CoreLocation
import Foundation

public struct ShiftLocationState: Codable, Equatable {
    public var locationAuthStatus: CLAuthorizationStatus
    public var accuracyAuthorization: CLAccuracyAuthorization
    public var isInsideHomeRegion: Bool?
    public var isInsideWorkRegion: Bool?
    public var homeExitTimestamp: Date?
    public var workEntryTimestamp: Date?
    public var hasConfirmedDeparture: Bool
    public var hasConfirmedArrival: Bool

    public init(
        locationAuthStatus: CLAuthorizationStatus = .notDetermined,
        accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy,
        isInsideHomeRegion: Bool? = nil,
        isInsideWorkRegion: Bool? = nil,
        homeExitTimestamp: Date? = nil,
        workEntryTimestamp: Date? = nil,
        hasConfirmedDeparture: Bool = false,
        hasConfirmedArrival: Bool = false
    ) {
        self.locationAuthStatus = locationAuthStatus
        self.accuracyAuthorization = accuracyAuthorization
        self.isInsideHomeRegion = isInsideHomeRegion
        self.isInsideWorkRegion = isInsideWorkRegion
        self.homeExitTimestamp = homeExitTimestamp
        self.workEntryTimestamp = workEntryTimestamp
        self.hasConfirmedDeparture = hasConfirmedDeparture
        self.hasConfirmedArrival = hasConfirmedArrival
    }

    private enum CodingKeys: String, CodingKey {
        case locationAuthStatusRaw
        case accuracyAuthorizationRaw
        case isInsideHomeRegion
        case isInsideWorkRegion
        case homeExitTimestamp
        case workEntryTimestamp
        case hasConfirmedDeparture
        case hasConfirmedArrival
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let authRaw = try container.decode(Int32.self, forKey: .locationAuthStatusRaw)
        locationAuthStatus = CLAuthorizationStatus(rawValue: authRaw) ?? .notDetermined
        let accuracyRaw = try container.decode(Int.self, forKey: .accuracyAuthorizationRaw)
        accuracyAuthorization = CLAccuracyAuthorization(rawValue: accuracyRaw) ?? .fullAccuracy
        isInsideHomeRegion = try container.decodeIfPresent(Bool.self, forKey: .isInsideHomeRegion)
        isInsideWorkRegion = try container.decodeIfPresent(Bool.self, forKey: .isInsideWorkRegion)
        homeExitTimestamp = try container.decodeIfPresent(Date.self, forKey: .homeExitTimestamp)
        workEntryTimestamp = try container.decodeIfPresent(Date.self, forKey: .workEntryTimestamp)
        hasConfirmedDeparture = try container.decode(Bool.self, forKey: .hasConfirmedDeparture)
        hasConfirmedArrival = try container.decode(Bool.self, forKey: .hasConfirmedArrival)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locationAuthStatus.rawValue, forKey: .locationAuthStatusRaw)
        try container.encode(accuracyAuthorization.rawValue, forKey: .accuracyAuthorizationRaw)
        try container.encodeIfPresent(isInsideHomeRegion, forKey: .isInsideHomeRegion)
        try container.encodeIfPresent(isInsideWorkRegion, forKey: .isInsideWorkRegion)
        try container.encodeIfPresent(homeExitTimestamp, forKey: .homeExitTimestamp)
        try container.encodeIfPresent(workEntryTimestamp, forKey: .workEntryTimestamp)
        try container.encode(hasConfirmedDeparture, forKey: .hasConfirmedDeparture)
        try container.encode(hasConfirmedArrival, forKey: .hasConfirmedArrival)
    }
}
