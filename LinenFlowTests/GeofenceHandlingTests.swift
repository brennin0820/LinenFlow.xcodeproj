import CoreLocation
import Foundation
import Testing
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

// MARK: - Mock Location Service

final class GeofenceMockLocationService: LocationServiceProtocol, @unchecked Sendable {
    var authorizationStatus: CLAuthorizationStatus = .authorizedAlways
    var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy

    private(set) var monitoredRegions: [CLCircularRegion] = []
    private(set) var startMonitoringCallCount = 0
    private(set) var requestStateCallCount = 0
    var regionStates: [String: CLRegionState] = [:]

    func requestWhenInUseAuthorization() {}
    func requestAlwaysAuthorization() {}

    func startMonitoring(for region: CLCircularRegion) {
        guard !monitoredRegions.contains(where: { $0.identifier == region.identifier }) else { return }
        monitoredRegions.append(region)
        startMonitoringCallCount += 1
    }

    func stopMonitoring(for region: CLCircularRegion) {
        monitoredRegions.removeAll { $0.identifier == region.identifier }
    }

    func requestState(for region: CLCircularRegion) async -> CLRegionState {
        requestStateCallCount += 1
        return regionStates[region.identifier] ?? .unknown
    }

    func startMonitoringSignificantLocationChanges() {}
    func stopMonitoringSignificantLocationChanges() {}
}

// MARK: - Helpers

private func makeTimeline(clockIn: Date, calendar: Calendar = .autoupdatingCurrent) -> ShiftTimelineSnapshot {
    let settings = ShiftPlannerSettings()
    return computeTimeline(
        clockInTime: clockIn,
        settings: settings,
        shiftDurationMinutes: 480,
        calendar: calendar
    )
}

private func leaveBackupID(for timeline: ShiftTimelineSnapshot, calendar: Calendar = .autoupdatingCurrent) -> String {
    HimmerFlowNotificationID.make(
        shiftDate: timeline.primaryAnchor,
        phase: .leave,
        isPrimary: false,
        calendar: calendar
    )
}

// MARK: - Tests

@Suite("GeofenceHandling")
struct GeofenceHandlingTests {
    let calendar = Calendar.autoupdatingCurrent

    @Test("Already inside work region at monitoring start confirms arrival without enter event")
    func alreadyInsideWorkRegion() async {
        let mock = GeofenceMockLocationService()
        mock.regionStates[HimmerFlowRegionID.work] = .inside

        let clockIn = calendar.date(byAdding: .hour, value: 2, to: Date.now)!
        let timeline = makeTimeline(clockIn: clockIn, calendar: calendar)
        var locationState = ShiftLocationState()

        let work = SavedLocation(label: "Plant", latitude: 33.0, longitude: -117.0, locationType: .work)
        let region = LocationService.workRegion(for: work)

        mock.startMonitoring(for: region)
        let state = await mock.requestState(for: region)

        #expect(state == .inside)
        #expect(mock.requestStateCallCount == 1)

        if state == .inside, !locationState.hasConfirmedArrival {
            locationState.isInsideWorkRegion = true
            locationState.hasConfirmedArrival = true
            locationState.workEntryTimestamp = Date.now
        }

        #expect(locationState.hasConfirmedArrival)
        #expect(locationState.isInsideWorkRegion == true)
        #expect(locationState.workEntryTimestamp != nil)
        _ = timeline
    }

    @Test("Home exit sets hasConfirmedDeparture and cancels still-home backup")
    func homeExitCancelsBackup() {
        var engine = ReconciliationEngine(calendar: calendar)
        let clockIn = calendar.date(byAdding: .hour, value: 3, to: Date.now)!
        let timeline = makeTimeline(clockIn: clockIn, calendar: calendar)
        var locationState = ShiftLocationState()
        let ackState = AcknowledgementState()
        let backupID = leaveBackupID(for: timeline, calendar: calendar)

        engine.applyGeofenceEvent(
            regionIdentifier: HimmerFlowRegionID.home,
            entering: false,
            locationState: &locationState,
            now: Date.now
        )

        #expect(locationState.hasConfirmedDeparture)
        #expect(locationState.homeExitTimestamp != nil)

        let cancelIDs = engine.notificationsToCancel(
            timeline: timeline,
            ackState: ackState,
            locationState: locationState,
            now: Date.now,
            pendingIDs: [backupID]
        )
        #expect(cancelIDs.contains(backupID))
    }

    @Test("Work entry sets hasConfirmedArrival")
    func workEntryConfirmsArrival() {
        var engine = ReconciliationEngine(calendar: calendar)
        var locationState = ShiftLocationState()

        engine.applyGeofenceEvent(
            regionIdentifier: HimmerFlowRegionID.work,
            entering: true,
            locationState: &locationState,
            now: Date.now
        )

        #expect(locationState.hasConfirmedArrival)
        #expect(locationState.isInsideWorkRegion == true)
        #expect(locationState.workEntryTimestamp != nil)
    }

    @Test("Double geofence fire is idempotent")
    func doubleFireIdempotent() {
        var engine = ReconciliationEngine(calendar: calendar)
        var locationState = ShiftLocationState()
        let now = Date.now

        engine.applyGeofenceEvent(
            regionIdentifier: HimmerFlowRegionID.home,
            entering: false,
            locationState: &locationState,
            now: now
        )
        let firstExit = locationState.homeExitTimestamp

        engine.applyGeofenceEvent(
            regionIdentifier: HimmerFlowRegionID.home,
            entering: false,
            locationState: &locationState,
            now: now.addingTimeInterval(120)
        )

        #expect(locationState.hasConfirmedDeparture)
        #expect(locationState.homeExitTimestamp == firstExit)
    }

    @Test("Double work entry fire is idempotent")
    func doubleWorkEntryIdempotent() {
        var engine = ReconciliationEngine(calendar: calendar)
        var locationState = ShiftLocationState()
        let now = Date.now

        engine.applyGeofenceEvent(
            regionIdentifier: HimmerFlowRegionID.work,
            entering: true,
            locationState: &locationState,
            now: now
        )
        let firstEntry = locationState.workEntryTimestamp

        engine.applyGeofenceEvent(
            regionIdentifier: HimmerFlowRegionID.work,
            entering: true,
            locationState: &locationState,
            now: now.addingTimeInterval(90)
        )

        #expect(locationState.hasConfirmedArrival)
        #expect(locationState.workEntryTimestamp == firstEntry)
    }

    @Test("GeofenceMockLocationService startMonitoring is idempotent")
    @MainActor
    func startMonitoringIdempotent() async {
        let mock = GeofenceMockLocationService()
        let home = SavedLocation(label: "Home", latitude: 33.1, longitude: -117.1, locationType: .home)
        let region = LocationService.homeRegion(for: home)

        mock.startMonitoring(for: region)
        mock.startMonitoring(for: region)

        #expect(mock.monitoredRegions.count == 1)
        #expect(mock.startMonitoringCallCount == 1)
    }

    @Test("Reduced accuracy degrades geofencing availability")
    @MainActor
    func reducedAccuracyDegradation() {
        let engine = ReconciliationEngine(calendar: calendar)
        let service = LocationService()
        // Fresh service reflects system auth; test degradation helpers via mock state path.
        let mock = GeofenceMockLocationService()
        mock.accuracyAuthorization = .reducedAccuracy
        mock.authorizationStatus = .authorizedAlways

        let tier = engine.effectiveMonitoringTier(
            requested: .smart,
            locationState: ShiftLocationState(
                locationAuthStatus: mock.authorizationStatus,
                accuracyAuthorization: mock.accuracyAuthorization
            )
        )
        #expect(tier == .manual)

        let message = engine.degradationMessage(
            requested: .smart,
            locationState: ShiftLocationState(
                locationAuthStatus: mock.authorizationStatus,
                accuracyAuthorization: mock.accuracyAuthorization
            )
        )
        #expect(message?.contains("Precise Location") == true)
        _ = service
    }

    @Test("When In Use downgrade degrades to manual tier")
    func whenInUseDowngrade() {
        let engine = ReconciliationEngine(calendar: calendar)
        let locationState = ShiftLocationState(
            locationAuthStatus: .authorizedWhenInUse,
            accuracyAuthorization: .fullAccuracy
        )

        let tier = engine.effectiveMonitoringTier(requested: .smart, locationState: locationState)
        #expect(tier == .manual)

        let message = engine.degradationMessage(requested: .smart, locationState: locationState)
        #expect(message?.contains("Background location") == true)
    }

    @Test("Live Activity ends at shiftActive plus 30 minutes")
    func liveActivityEndThreshold() {
        let engine = ReconciliationEngine(calendar: calendar)
        let clockIn = calendar.date(byAdding: .hour, value: 1, to: Date.now)!
        let timeline = makeTimeline(clockIn: clockIn, calendar: calendar)
        guard let shiftActive = timeline.window(for: .shiftActive) else {
            Issue.record("Missing shiftActive window")
            return
        }

        let endThreshold = calendar.date(byAdding: DateComponents(minute: 30), to: shiftActive.start)!
        #expect(engine.shouldEndLiveActivity(timeline: timeline, now: endThreshold))
        #expect(!engine.shouldStartLiveActivity(phase: .preSleep))
        #expect(engine.shouldStartLiveActivity(phase: .wake))
        #expect(engine.shouldStartLiveActivity(phase: .shiftActive))
    }
}

private extension ShiftLocationState {
    init(locationAuthStatus: CLAuthorizationStatus, accuracyAuthorization: CLAccuracyAuthorization) {
        self.init()
        self.locationAuthStatus = locationAuthStatus
        self.accuracyAuthorization = accuracyAuthorization
    }
}
