import CoreLocation
import Foundation

protocol LocationServiceProtocol: AnyObject, Sendable {
    var authorizationStatus: CLAuthorizationStatus { get }
    var accuracyAuthorization: CLAccuracyAuthorization { get }
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func startMonitoring(for region: CLCircularRegion)
    func stopMonitoring(for region: CLCircularRegion)
    func requestState(for region: CLCircularRegion) async -> CLRegionState
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
}

enum HimmerFlowRegionID {
    static let home = "himmerflow.home"
    static let work = "himmerflow.work"
}
