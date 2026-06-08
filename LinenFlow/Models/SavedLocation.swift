import CoreLocation
import Foundation
import SwiftData

@Model
final class SavedLocation {
    var id: UUID
    var label: String
    var latitude: Double
    var longitude: Double
    var radiusMeters: Double
    var locationTypeRaw: String

    enum LocationType: String, Codable, Sendable {
        case home
        case work
    }

    var locationType: LocationType {
        get { LocationType(rawValue: locationTypeRaw) ?? .work }
        set { locationTypeRaw = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        label: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double = 200,
        locationType: LocationType = .work
    ) {
        self.id = id
        self.label = label
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = min(max(radiusMeters, 100), 500)
        self.locationTypeRaw = locationType.rawValue
    }
}
