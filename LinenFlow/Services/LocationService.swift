import CoreLocation
import Observation

@Observable
@MainActor
final class LocationService: NSObject {
    private let manager = CLLocationManager()
    private(set) var authStatus: CLAuthorizationStatus = .notDetermined
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private var pendingContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authStatus = manager.authorizationStatus
    }

    func fetchCurrentLocation() async -> CLLocationCoordinate2D? {
        guard pendingContinuation == nil else { return nil }
        isLoading = true
        errorMessage = nil
        return await withCheckedContinuation { cont in
            pendingContinuation = cont
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                errorMessage = "Location access denied. Enable in Settings → Privacy → Location Services."
                isLoading = false
                cont.resume(returning: nil)
                pendingContinuation = nil
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoading = false
        authStatus = manager.authorizationStatus
        pendingContinuation?.resume(returning: locations.first?.coordinate)
        pendingContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = "Couldn't get location. Try again."
        pendingContinuation?.resume(returning: nil)
        pendingContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        guard pendingContinuation != nil else { return }
        switch authStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Location access denied. Enable in Settings → Privacy → Location Services."
            isLoading = false
            pendingContinuation?.resume(returning: nil)
            pendingContinuation = nil
        default:
            break
        }
    }
}
