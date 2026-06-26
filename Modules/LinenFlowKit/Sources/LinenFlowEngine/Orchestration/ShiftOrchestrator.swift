import CoreLocation
import Foundation
import Observation
import OSLog
import SwiftData
import LinenFlowCore

// MARK: - ShiftOrchestrator (HimmerFlow spec §4, §5 chains A/B/C)
//
// Central coordinator: schedule up front, reconcile on every wake.
// TODO: If LocationServiceProtocol / NotificationServiceProtocol move, update imports only.

@MainActor
@Observable
public final class ShiftOrchestrator {
    public enum ReconciliationTrigger: Sendable, CustomStringConvertible {
        case appForeground
        case settingsChanged
        case geofenceEvent(regionIdentifier: String, entering: Bool)
        case significantLocationChange
        case notificationAction(ShiftTimelinePhase, acknowledged: Bool)
        case timerTick

        public var description: String {
            switch self {
            case .appForeground: return "appForeground"
            case .settingsChanged: return "settingsChanged"
            case .geofenceEvent(let id, let entering): return "geofenceEvent(\(id), entering: \(entering))"
            case .significantLocationChange: return "significantLocationChange"
            case .notificationAction(let phase, let ack): return "notificationAction(\(phase.rawValue), ack: \(ack))"
            case .timerTick: return "timerTick"
            }
        }
    }

    private(set) var currentTimeline: ShiftTimelineSnapshot?
    private(set) var currentPhase: ShiftTimelinePhase = .idle
    private(set) var locationState: ShiftLocationState
    private(set) var ackState: AcknowledgementState
    private(set) var settings: ShiftPlannerSettings
    private(set) var activePattern: ShiftPattern?
    private(set) var degradationMessage: String?
    private(set) var isOffToday: Bool = true

    private let notificationService: any NotificationServiceProtocol
    private let activityService: any LiveActivityServiceProtocol
    private let locationService: (any LocationServiceProtocol)?
    private let clock: any ClockProtocol
    private let calendar: Calendar
    private var engine: ReconciliationEngine
    private var activityID: String?
    private nonisolated(unsafe) let modelContext: ModelContext
    private let injectedSchedule: (pattern: ShiftPattern?, timeline: ShiftTimelineSnapshot?)?

    private let logger = Logger(subsystem: "com.himmerflow", category: "orchestrator")

    public init(
        modelContext: ModelContext,
        settings: ShiftPlannerSettings,
        notificationService: any NotificationServiceProtocol = NotificationService(),
        activityService: any LiveActivityServiceProtocol = LiveActivityService(),
        locationService: (any LocationServiceProtocol)? = nil,
        clock: any ClockProtocol = SystemClock(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.modelContext = modelContext
        self.settings = settings
        self.notificationService = notificationService
        self.activityService = activityService
        self.locationService = locationService
        self.clock = clock
        self.calendar = calendar
        self.engine = ReconciliationEngine(calendar: calendar)
        self.locationState = ShiftPlannerPersistence.loadLocationState()
        self.ackState = ShiftPlannerPersistence.loadAcknowledgementState()
        self.activityID = ShiftPlannerPersistence.loadActivityID()
        self.injectedSchedule = nil
    }

    /// Test / preview hook: inject resolved shift without SwiftData fetch.
    public init(
        settings: ShiftPlannerSettings,
        pattern: ShiftPattern?,
        timeline: ShiftTimelineSnapshot?,
        notificationService: any NotificationServiceProtocol,
        activityService: any LiveActivityServiceProtocol,
        locationService: (any LocationServiceProtocol)? = nil,
        clock: any ClockProtocol,
        calendar: Calendar = .autoupdatingCurrent,
        locationState: ShiftLocationState = ShiftLocationState(),
        ackState: AcknowledgementState = AcknowledgementState(),
        activityID: String? = nil
    ) {
        self.modelContext = ModelContext(
            try! ModelContainer(
                for: ShiftPlannerSettings.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
        self.settings = settings
        self.notificationService = notificationService
        self.activityService = activityService
        self.locationService = locationService
        self.clock = clock
        self.calendar = calendar
        self.engine = ReconciliationEngine(calendar: calendar)
        self.locationState = locationState
        self.ackState = ackState
        self.activityID = activityID
        self.injectedSchedule = (pattern, timeline)
        self.activePattern = pattern
        self.currentTimeline = timeline
        self.currentPhase = timeline?.currentPhase(at: clock.now) ?? .idle
        self.isOffToday = timeline == nil
    }

    // MARK: - Reconciliation (§3, §4, §5)

    public func reconcile(trigger: ReconciliationTrigger) async {
        let previousPhase = currentPhase
        refreshLocationAuth()

        await reloadShiftContext()

        if case .geofenceEvent(let regionID, let entering) = trigger {
            engine.applyGeofenceEvent(
                regionIdentifier: regionID,
                entering: entering,
                locationState: &locationState,
                now: clock.now
            )
        }

        if case .notificationAction(let phase, let acknowledged) = trigger, acknowledged {
            ackState.acknowledge(phase)
        }

        switch trigger {
        case .settingsChanged:
            // Chain A: cancel all, schedule fresh set from new timeline.
            await notificationService.cancelAll()
            await scheduleNotificationsIfNeeded()
        default:
            await reconcileNotifications()
        }

        await reconcileLiveActivity()
        await reconcileGeofences()

        ShiftPlannerPersistence.saveLocationState(locationState)
        ShiftPlannerPersistence.saveAcknowledgementState(ackState)
        ShiftPlannerPersistence.saveActivityID(activityID)

        logger.info(
            """
            Reconcile triggered: \(trigger.description, privacy: .public), \
            phase: \(previousPhase.rawValue) → \(self.currentPhase.rawValue), \
            location: home=\(self.locationState.isInsideHomeRegion.map(String.init(describing:)) ?? "nil"), \
            work=\(self.locationState.isInsideWorkRegion.map(String.init(describing:)) ?? "nil")
            """
        )
    }

    public func acknowledge(phase: ShiftTimelinePhase) async {
        ackState.acknowledge(phase)
        await reconcile(trigger: .notificationAction(phase, acknowledged: true))
    }

    public func snooze(phase: ShiftTimelinePhase) async {
        guard let timeline = currentTimeline, timeline.window(for: phase) != nil else { return }
        let snoozeDate = calendar.date(
            byAdding: DateComponents(minute: NotificationPlanner.snoozeDelayMinutes),
            to: clock.now
        )!
        let id = "himmerflow.snooze.\(phase.rawValue).\(Int(snoozeDate.timeIntervalSince1970))"
        let request = NotificationService.makeRequest(
            identifier: id,
            title: phase.displayName,
            body: "Snoozed — check in now.",
            fireDate: snoozeDate,
            calendar: calendar,
            requiresAck: phase.requiresAcknowledgement
        )
        try? await notificationService.schedule(request)
        logger.info("Snooze scheduled for phase \(phase.rawValue)")
    }

    // MARK: - Private helpers

    private func refreshLocationAuth() {
        guard let locationService else { return }
        locationState.locationAuthStatus = locationService.authorizationStatus
        locationState.accuracyAuthorization = locationService.accuracyAuthorization
        degradationMessage = engine.degradationMessage(
            requested: settings.monitoringTier,
            locationState: locationState
        )
    }

    private func reloadShiftContext() async {
        if let injectedSchedule {
            activePattern = injectedSchedule.pattern
            currentTimeline = injectedSchedule.timeline
            currentPhase = injectedSchedule.timeline?.currentPhase(at: clock.now) ?? .idle
            isOffToday = injectedSchedule.timeline == nil
            return
        }

        let patterns = await fetchPatterns()
        activePattern = selectActivePattern(from: patterns, now: clock.now)

        if let pattern = activePattern,
           let anchor = pattern.nextOccurrence(after: clock.now.addingTimeInterval(-86400), calendar: calendar) {
            currentTimeline = computeTimeline(
                clockInTime: resolvedAnchor(for: pattern, candidate: anchor),
                settings: settings,
                shiftDurationMinutes: pattern.shiftDurationMinutes,
                calendar: calendar
            )
            currentPhase = currentTimeline?.currentPhase(at: clock.now) ?? .idle
            isOffToday = !isShiftRelevant(pattern: pattern, timeline: currentTimeline, now: clock.now)
        } else {
            currentTimeline = nil
            currentPhase = .idle
            isOffToday = true
        }
    }

    private func fetchPatterns() async -> [ShiftPattern] {
        (try? modelContext.fetch(FetchDescriptor<ShiftPattern>())) ?? []
    }

    private func selectActivePattern(from patterns: [ShiftPattern], now: Date) -> ShiftPattern? {
        let active = patterns.filter(\.isActive)
        return active.min { lhs, rhs in
            let left = lhs.nextOccurrence(after: now.addingTimeInterval(-3600), calendar: calendar) ?? .distantFuture
            let right = rhs.nextOccurrence(after: now.addingTimeInterval(-3600), calendar: calendar) ?? .distantFuture
            return left < right
        }
    }

    private func resolvedAnchor(for pattern: ShiftPattern, candidate: Date) -> Date {
        if candidate > clock.now { return candidate }
        return pattern.nextOccurrence(after: clock.now, calendar: calendar) ?? candidate
    }

    private func isShiftRelevant(pattern: ShiftPattern, timeline: ShiftTimelineSnapshot?, now: Date) -> Bool {
        guard let timeline else { return false }
        guard timeline.phases.first != nil else { return false }
        let last = timeline.phases.last?.end ?? timeline.primaryAnchor
        let weekday = Weekday(calendarWeekday: calendar.component(.weekday, from: now)) ?? .sunday
        return now <= last && pattern.daysOfWeek.contains(weekday)
    }

    private func scheduleNotificationsIfNeeded() async {
        guard let timeline = currentTimeline, let pattern = activePattern else { return }
        let requests = NotificationPlanner.requests(
            for: timeline,
            settings: settings,
            patternName: pattern.name,
            calendar: calendar
        )
        let pending = await notificationService.scheduledNotificationCount()
        let capacity = engine.remainingScheduleCapacity(currentCount: pending)
        for request in requests.prefix(capacity) {
            try? await notificationService.schedule(request)
        }
    }

    private func reconcileNotifications() async {
        let pending = await notificationService.pendingIdentifiers()
        let cancel = engine.notificationsToCancel(
            timeline: currentTimeline,
            ackState: ackState,
            locationState: locationState,
            now: clock.now,
            pendingIDs: pending
        )
        await notificationService.cancel(identifiers: cancel)

        let count = await notificationService.scheduledNotificationCount()
        if count < 8 {
            await scheduleNotificationsIfNeeded()
        }
    }

    private func reconcileLiveActivity() async {
        let action = engine.liveActivityAction(
            timeline: currentTimeline,
            patternName: activePattern?.name ?? "Shift",
            phase: currentPhase,
            now: clock.now,
            hasActivity: activityID != nil
        )

        switch action {
        case .none:
            break
        case .start(let content):
            guard activityService.canStartFromBackground || isForegroundTrigger else { return }
            do {
                activityID = try await activityService.start(initialContent: content)
                logger.info("Live Activity started for phase \(self.currentPhase.rawValue)")
            } catch {
                logger.error("Failed to start activity: \(error.localizedDescription, privacy: .public)")
            }
        case .update(let content):
            guard let id = activityID else { return }
            await activityService.update(activityID: id, content: content)
            logger.info("Live Activity updated for phase \(self.currentPhase.rawValue)")
        case .end(let content):
            guard let id = activityID else { return }
            await activityService.end(activityID: id, finalContent: content)
            activityID = nil
            logger.info("Live Activity ended")
        }
    }

    private var isForegroundTrigger: Bool { true }

    private func reconcileGeofences() async {
        guard let locationService else { return }

        let tier = engine.effectiveMonitoringTier(
            requested: settings.monitoringTier,
            locationState: locationState
        )
        let regions = engine.regionsToMonitor(
            home: settings.homeLocation,
            work: activePattern?.workLocation,
            tier: tier
        )

        if tier == .manual {
            logger.info("Geofence reconcile: manual tier — no regions monitored")
        }

        for monitored in regions {
            let region = engine.circularRegion(
                for: monitored.location,
                identifier: monitored.identifier,
                notifyOnEntry: monitored.notifyOnEntry,
                notifyOnExit: monitored.notifyOnExit
            )
            locationService.startMonitoring(for: region)
            let state = await locationService.requestState(for: region)
            engine.applyInitialRegionState(
                identifier: monitored.identifier,
                state: state,
                locationState: &locationState,
                now: clock.now
            )
        }

        if engine.shouldUseSignificantChangeMonitoring(tier: tier, locationState: locationState) {
            locationService.startMonitoringSignificantLocationChanges()
        } else {
            locationService.stopMonitoringSignificantLocationChanges()
        }
    }
}
