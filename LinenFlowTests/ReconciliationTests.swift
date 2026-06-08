import CoreLocation
import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import HimmerFlow

// MARK: - Mocks (workstream 2 provides production mocks; local copies for reconciliation tests)

final class ReconciliationMockNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    var pendingIDs: [String] = []
    var cancelledIDs: [String] = []
    var scheduledIDs: [String] = []
    var didCancelAll = false

    func scheduledNotificationCount() async -> Int { pendingIDs.count }

    func schedule(_ request: UNNotificationRequest) async throws {
        scheduledIDs.append(request.identifier)
        if !pendingIDs.contains(request.identifier) {
            pendingIDs.append(request.identifier)
        }
    }

    func cancel(identifiers: [String]) async {
        cancelledIDs.append(contentsOf: identifiers)
        pendingIDs.removeAll { identifiers.contains($0) }
    }

    func cancelAll() async {
        didCancelAll = true
        pendingIDs.removeAll()
    }

    func pendingIdentifiers() async -> [String] { pendingIDs }

    func registerCategories() async {}
}

final class ReconciliationMockLocationService: LocationServiceProtocol, @unchecked Sendable {
    var authorizationStatus: CLAuthorizationStatus = .authorizedAlways
    var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy
    var startedRegionIDs: [String] = []
    var stoppedSignificantChanges = false
    var regionStates: [String: CLRegionState] = [:]

    func requestWhenInUseAuthorization() {}
    func requestAlwaysAuthorization() {}

    func startMonitoring(for region: CLCircularRegion) {
        startedRegionIDs.append(region.identifier)
    }

    func stopMonitoring(for region: CLCircularRegion) {}

    func requestState(for region: CLCircularRegion) async -> CLRegionState {
        regionStates[region.identifier] ?? .unknown
    }

    func startMonitoringSignificantLocationChanges() {
        stoppedSignificantChanges = false
    }

    func stopMonitoringSignificantLocationChanges() {
        stoppedSignificantChanges = true
    }
}

final class ReconciliationMockLiveActivityService: LiveActivityServiceProtocol, @unchecked Sendable {
    var canStartFromBackground: Bool = false
    var activityID: String?
    var updates: Int = 0
    var ended = false

    func start(initialContent: ShiftActivityContent) async throws -> String {
        activityID = "mock-activity"
        return activityID!
    }

    func update(activityID: String, content: ShiftActivityContent) async {
        updates += 1
    }

    func end(activityID: String, finalContent: ShiftActivityContent) async {
        ended = true
        self.activityID = nil
    }
}

// MARK: - Fixtures

private enum ReconciliationFixtures {
    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Chicago")!
        return cal
    }

    static func settings() -> ShiftPlannerSettings {
        ShiftPlannerSettings(
            sleepDurationMinutes: 480,
            getReadyDurationMinutes: 45,
            walkToCarMinutes: 5,
            commuteDurationMinutes: 30,
            parkingWalkMinutes: 10,
            walkInMinutes: 5,
            arrivalBufferMinutes: 15,
            preSleepWindDownMinutes: 30,
            beDownMinutesAfterShift: 60,
            monitoringTier: .smart
        )
    }

    static func nightShiftTimeline(calendar: Calendar = calendar) -> ShiftTimelineSnapshot {
        var components = DateComponents(year: 2026, month: 6, day: 8, hour: 23, minute: 0)
        let clockIn = calendar.date(from: components)!
        return computeTimeline(
            clockInTime: clockIn,
            settings: settings(),
            shiftDurationMinutes: 480,
            calendar: calendar
        )
    }

    static func leaveBackupID(timeline: ShiftTimelineSnapshot, calendar: Calendar = calendar) -> String {
        HimmerFlowNotificationID.make(
            shiftDate: timeline.primaryAnchor,
            phase: .leave,
            isPrimary: false,
            calendar: calendar
        )
    }

    static func wakeBackupID(timeline: ShiftTimelineSnapshot, calendar: Calendar = calendar) -> String {
        HimmerFlowNotificationID.make(
            shiftDate: timeline.primaryAnchor,
            phase: .wake,
            isPrimary: false,
            calendar: calendar
        )
    }
}

// MARK: - ReconciliationEngine tests (§13)

@Suite("ReconciliationTests")
struct ReconciliationTests {

    @Test("Geofence exit cancels leave backup while notifications pending")
    func geofenceExitCancelsBackup() {
        let calendar = ReconciliationFixtures.calendar
        var engine = ReconciliationEngine(calendar: calendar)
        let timeline = ReconciliationFixtures.nightShiftTimeline(calendar: calendar)
        let backupID = ReconciliationFixtures.leaveBackupID(timeline: timeline, calendar: calendar)

        var locationState = ShiftLocationState()
        locationState.hasConfirmedDeparture = false

        engine.applyGeofenceEvent(
            regionIdentifier: HimmerFlowRegionID.home,
            entering: false,
            locationState: &locationState,
            now: timeline.window(for: .leave)!.start
        )

        #expect(locationState.hasConfirmedDeparture)

        let cancel = engine.notificationsToCancel(
            timeline: timeline,
            ackState: AcknowledgementState(),
            locationState: locationState,
            now: timeline.window(for: .leave)!.start,
            pendingIDs: [backupID]
        )

        #expect(cancel == [backupID])
    }

    @Test("Double geofence fire is idempotent")
    func doubleGeofenceFireIsIdempotent() {
        let calendar = ReconciliationFixtures.calendar
        var engine = ReconciliationEngine(calendar: calendar)
        var locationState = ShiftLocationState()
        let exitTime = Date(timeIntervalSince1970: 1_700_000_000)

        let first = engine.applyGeofenceEvent(
            regionIdentifier: HimmerFlowRegionID.home,
            entering: false,
            locationState: &locationState,
            now: exitTime
        )
        let second = engine.applyGeofenceEvent(
            regionIdentifier: HimmerFlowRegionID.home,
            entering: false,
            locationState: &locationState,
            now: exitTime.addingTimeInterval(120)
        )

        #expect(first)
        #expect(!second)
        #expect(locationState.hasConfirmedDeparture)
        #expect(locationState.homeExitTimestamp == exitTime)
    }

    @Test("Acknowledged phase cancels backup on reconciliation")
    func ackCancelsBackup() {
        let calendar = ReconciliationFixtures.calendar
        let engine = ReconciliationEngine(calendar: calendar)
        let timeline = ReconciliationFixtures.nightShiftTimeline(calendar: calendar)
        let backupID = ReconciliationFixtures.wakeBackupID(timeline: timeline, calendar: calendar)

        var ackState = AcknowledgementState()
        ackState.acknowledge(.wake)

        let cancel = engine.notificationsToCancel(
            timeline: timeline,
            ackState: ackState,
            locationState: ShiftLocationState(),
            now: timeline.window(for: .wake)!.start,
            pendingIDs: [backupID]
        )

        #expect(cancel == [backupID])
    }

    @Test("Auth downgrade stops geofence monitoring tier")
    func authDowngradeFallsBackToManual() {
        let engine = ReconciliationEngine(calendar: ReconciliationFixtures.calendar)
        var locationState = ShiftLocationState()
        locationState.locationAuthStatus = .authorizedWhenInUse
        locationState.accuracyAuthorization = .fullAccuracy

        let tier = engine.effectiveMonitoringTier(requested: .smart, locationState: locationState)
        let regions = engine.regionsToMonitor(
            home: SavedLocation(label: "Home", latitude: 1, longitude: 1, locationType: .home),
            work: SavedLocation(label: "Work", latitude: 2, longitude: 2, locationType: .work),
            tier: tier
        )

        #expect(tier == .manual)
        #expect(regions.isEmpty)
        #expect(engine.degradationMessage(requested: .smart, locationState: locationState) != nil)
    }

    @Test("Approximate location disables geofences")
    func approximateLocationDisablesGeofences() {
        let engine = ReconciliationEngine(calendar: ReconciliationFixtures.calendar)
        var locationState = ShiftLocationState()
        locationState.locationAuthStatus = .authorizedAlways
        locationState.accuracyAuthorization = .reducedAccuracy

        let tier = engine.effectiveMonitoringTier(requested: .activeCommute, locationState: locationState)
        let regions = engine.regionsToMonitor(
            home: SavedLocation(label: "Home", latitude: 1, longitude: 1, locationType: .home),
            work: SavedLocation(label: "Work", latitude: 2, longitude: 2, locationType: .work),
            tier: tier
        )

        #expect(tier == .manual)
        #expect(regions.isEmpty)
        #expect(engine.degradationMessage(requested: .activeCommute, locationState: locationState)?.contains("Precise") == true)
    }
}

// MARK: - ShiftOrchestrator integration (Chain B)

@Suite("ShiftOrchestrator reconciliation")
@MainActor
struct ShiftOrchestratorReconciliationTests {

    @Test("Geofence reconcile cancels leave backup via orchestrator")
    func orchestratorGeofenceExitCancelsBackup() async {
        let calendar = ReconciliationFixtures.calendar
        let timeline = ReconciliationFixtures.nightShiftTimeline(calendar: calendar)
        let leaveStart = timeline.window(for: .leave)!.start
        let backupID = ReconciliationFixtures.leaveBackupID(timeline: timeline, calendar: calendar)

        let settings = ReconciliationFixtures.settings()
        let home = SavedLocation(label: "Home", latitude: 41.88, longitude: -87.63, locationType: .home)
        settings.homeLocation = home

        let pattern = ShiftPattern(
            name: "Night",
            daysOfWeek: [.monday, .tuesday, .wednesday, .thursday, .friday],
            clockInTime: DateComponents(hour: 23, minute: 0),
            shiftDurationMinutes: 480
        )

        let notifications = ReconciliationMockNotificationService()
        notifications.pendingIDs = [backupID]

        let location = ReconciliationMockLocationService()
        location.authorizationStatus = .authorizedAlways
        location.accuracyAuthorization = .fullAccuracy

        let orchestrator = ShiftOrchestrator(
            settings: settings,
            pattern: pattern,
            timeline: timeline,
            notificationService: notifications,
            activityService: ReconciliationMockLiveActivityService(),
            locationService: location,
            clock: FixedClock(fixedDate: leaveStart),
            calendar: calendar
        )

        await orchestrator.reconcile(trigger: .geofenceEvent(regionIdentifier: HimmerFlowRegionID.home, entering: false))

        #expect(notifications.cancelledIDs.contains(backupID))
        let state = orchestrator.locationState
        #expect(state.hasConfirmedDeparture)
    }
}
