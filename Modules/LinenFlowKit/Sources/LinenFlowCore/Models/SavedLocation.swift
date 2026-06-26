import CoreLocation
import Foundation
import SwiftData

@Model
public final class SavedLocation {
    public var id: UUID
    public var label: String
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    public var locationType: LocationType

    public enum LocationType: String, Codable {
        case home
        case work
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public init(
        id: UUID = UUID(),
        label: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double = 150,
        locationType: LocationType
    ) {
        self.id = id
        self.label = label
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.locationType = locationType
    }
}
