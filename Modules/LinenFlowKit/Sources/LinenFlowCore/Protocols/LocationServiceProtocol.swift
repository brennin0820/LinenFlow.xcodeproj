import CoreLocation
import Foundation

public protocol LocationServiceProtocol: AnyObject, Sendable {
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

public enum HimmerFlowRegionID {
    public nonisolated static let home = "himmerflow.home"
    public nonisolated static let work = "himmerflow.work"
}
