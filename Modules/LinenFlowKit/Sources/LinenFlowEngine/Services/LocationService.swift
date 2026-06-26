import CoreLocation
import Foundation
import Observation
import OSLog
import LinenFlowCore

/// CLLocationManager wrapper for HimmerFlow home/work geofences and significant-change monitoring.
@MainActor
@Observable
public final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var stateContinuations: [String: CheckedContinuation<CLRegionState, Never>] = [:]
    private var monitoredRegionIdentifiers: Set<String> = []
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    public var onRegionEvent: ((CLRegion, Bool) -> Void)?
    public var onSignificantLocationChange: ((CLLocation) -> Void)?

    public override init() {
        super.init()
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
    }

    public var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    public var accuracyAuthorization: CLAccuracyAuthorization {
        manager.accuracyAuthorization
    }

    /// Geofencing requires precise location and at least When In Use authorization.
    public var supportsGeofencing: Bool {
        let authorized: Bool
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            authorized = true
        default:
            authorized = false
        }
        return authorized && accuracyAuthorization == .fullAccuracy
    }

    /// Background geofence delivery requires Always authorization with precise location.
    public var supportsBackgroundGeofencing: Bool {
        authorizationStatus == .authorizedAlways && accuracyAuthorization == .fullAccuracy
    }

    public func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    public func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    public func startMonitoring(for region: CLCircularRegion) {
        guard !monitoredRegionIdentifiers.contains(region.identifier) else {
            HimmerFlowLog.location.debug("Already monitoring region: \(region.identifier, privacy: .public)")
            return
        }
        monitoredRegionIdentifiers.insert(region.identifier)
        manager.startMonitoring(for: region)
        HimmerFlowLog.location.info("Started monitoring region: \(region.identifier, privacy: .public)")
    }

    public func stopMonitoring(for region: CLCircularRegion) {
        guard monitoredRegionIdentifiers.contains(region.identifier) else { return }
        monitoredRegionIdentifiers.remove(region.identifier)
        manager.stopMonitoring(for: region)
        HimmerFlowLog.location.info("Stopped monitoring region: \(region.identifier, privacy: .public)")
    }

    /// Starts monitoring when needed, then immediately requests containment state (§7.1 already-inside edge case).
    public func startMonitoringAndRequestState(for region: CLCircularRegion) async -> CLRegionState {
        startMonitoring(for: region)
        return await requestState(for: region)
    }

    public func requestState(for region: CLCircularRegion) async -> CLRegionState {
        await withCheckedContinuation { continuation in
            stateContinuations[region.identifier] = continuation
            manager.requestState(for: region)
        }
    }

    public func startMonitoringSignificantLocationChanges() {
        manager.startMonitoringSignificantLocationChanges()
        HimmerFlowLog.location.info("Started significant-change monitoring")
    }

    public func stopMonitoringSignificantLocationChanges() {
        manager.stopMonitoringSignificantLocationChanges()
        HimmerFlowLog.location.info("Stopped significant-change monitoring")
    }

    public func fetchCurrentLocation() async -> CLLocationCoordinate2D? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            HimmerFlowLog.location.info("Region event: \(region.identifier, privacy: .public), entering: true")
            onRegionEvent?(region, true)
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            HimmerFlowLog.location.info("Region event: \(region.identifier, privacy: .public), entering: false")
            onRegionEvent?(region, false)
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        Task { @MainActor in
            stateContinuations.removeValue(forKey: region.identifier)?.resume(returning: state)
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(returning: location.coordinate)
            }
            onSignificantLocationChange?(location)
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }

    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if accuracyAuthorization == .reducedAccuracy {
                HimmerFlowLog.location.info("Degraded: reduced accuracy — geofencing unavailable")
            }
            if authorizationStatus == .authorizedWhenInUse {
                HimmerFlowLog.location.info("Degraded: When In Use only — background geofencing unavailable")
            }
        }
    }

    public nonisolated static func homeRegion(for location: SavedLocation) -> CLCircularRegion {
        circularRegion(for: location, identifier: HimmerFlowRegionID.home, notifyOnEntry: true, notifyOnExit: true)
    }

    public nonisolated static func workRegion(for location: SavedLocation) -> CLCircularRegion {
        circularRegion(for: location, identifier: HimmerFlowRegionID.work, notifyOnEntry: true, notifyOnExit: false)
    }

    public nonisolated static func circularRegion(
        for location: SavedLocation,
        identifier: String,
        notifyOnEntry: Bool,
        notifyOnExit: Bool
    ) -> CLCircularRegion {
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: location.radiusMeters,
            identifier: identifier
        )
        region.notifyOnEntry = notifyOnEntry
        region.notifyOnExit = notifyOnExit
        return region
    }
}
