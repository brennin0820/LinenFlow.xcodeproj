import CoreLocation
import MapKit
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
}
