import CoreLocation
import Foundation
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class MockLocationService: LocationServiceProtocol, @unchecked Sendable {
    var authorizationStatus: CLAuthorizationStatus = .authorizedAlways
    var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy
    var regionStates: [String: CLRegionState] = [:]
    private(set) var monitoredRegions: [String] = []
    private(set) var significantChangesStarted = false

    func requestWhenInUseAuthorization() {}

    func requestAlwaysAuthorization() {}

    func startMonitoring(for region: CLCircularRegion) {
        monitoredRegions.append(region.identifier)
    }

    func stopMonitoring(for region: CLCircularRegion) {
        monitoredRegions.removeAll { $0 == region.identifier }
    }

    func requestState(for region: CLCircularRegion) async -> CLRegionState {
        regionStates[region.identifier] ?? .unknown
    }

    func startMonitoringSignificantLocationChanges() {
        significantChangesStarted = true
    }

    func stopMonitoringSignificantLocationChanges() {
        significantChangesStarted = false
    }
}
