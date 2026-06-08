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
    var locationType: LocationType

    enum LocationType: String, Codable {
        case home
        case work
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
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
