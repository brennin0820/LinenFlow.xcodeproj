import CoreLocation
import MapKit
import SceneKit
import SwiftUI

enum HiltonPropertyMap {
    static let center = CLLocationCoordinate2D(latitude: 21.2831, longitude: -157.8371)
    static let region = MKCoordinateRegion(
        center: center,
        latitudinalMeters: 950,
        longitudinalMeters: 950
    )
    static let appleMapsURL = URL(string: "https://maps.apple.com/?q=Hilton+Hawaiian+Village&ll=21.2831,-157.8371&z=17")!

    /// Flyover-style satellite with extruded terrain and buildings.
    static var style3D: MapStyle {
        .imagery(elevation: .realistic)
    }

    static func overviewCamera(heading: Double = 24, pitch: Double = 62) -> MapCamera {
        MapCamera(
            centerCoordinate: center,
            distance: 880,
            heading: heading,
            pitch: pitch
        )
    }

    static func towerCamera(
        for coordinate: CLLocationCoordinate2D,
        heading: Double = 18,
        distance: CGFloat = 380
    ) -> MapCamera {
        MapCamera(
            centerCoordinate: coordinate,
            distance: distance,
            heading: heading,
            pitch: 72
        )
    }

    static func orbitHeading(at date: Date, start: Date) -> Double {
        let elapsed = date.timeIntervalSince(start)
        return 18 + sin(elapsed / 9) * 14
    }

    static func orbitPitch(at date: Date, start: Date) -> Double {
        let elapsed = date.timeIntervalSince(start)
        return 58 + sin(elapsed / 7) * 10
    }

    static func coordinate(for tower: Tower) -> CLLocationCoordinate2D? {
        guard let lat = tower.latitude, let lon = tower.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    static func mappedTowers(from towers: [Tower]) -> [(tower: Tower, coordinate: CLLocationCoordinate2D)] {
        towers.compactMap { tower in
            guard let coordinate = coordinate(for: tower) else { return nil }
            return (tower, coordinate)
        }
        .sorted { $0.tower.name < $1.tower.name }
    }

    /// Maps a geographic coordinate to a normalized XZ point on the custom 3D scene plane.
    /// Scene units span roughly ±6 across the property footprint (~950 m region).
    static func scenePosition(for coordinate: CLLocationCoordinate2D) -> SCNVector3 {
        let metersPerLatDegree = 111_320.0
        let metersPerLonDegree = 111_320.0 * cos(center.latitude * .pi / 180)
        let deltaLat = coordinate.latitude - center.latitude
        let deltaLon = coordinate.longitude - center.longitude
        let eastMeters = deltaLon * metersPerLonDegree
        let northMeters = deltaLat * metersPerLatDegree
        let sceneSpanMeters = region.span.latitudeDelta * metersPerLatDegree
        let scale = 12.0 / sceneSpanMeters

        return SCNVector3(
            Float(eastMeters * scale),
            0,
            Float(-northMeters * scale)
        )
    }

    static func scenePositions(
        from mappedTowers: [(tower: Tower, coordinate: CLLocationCoordinate2D)]
    ) -> [(tower: Tower, position: SCNVector3)] {
        mappedTowers.map { entry in
            (entry.tower, scenePosition(for: entry.coordinate))
        }
    }
}
