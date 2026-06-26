import CoreLocation
import Foundation
import OSLog
import LinenFlowCore

// MARK: - Reconciliation engine (HimmerFlow spec §3)
//
// Schedule conservatively up front; correct on every wake via notification, Live Activity,
// and geofence reconciliation. Pure decision logic lives here; side effects run in ShiftOrchestrator.

public struct ReconciliationEngine: Sendable {
    public let calendar: Calendar
    public let maxNotifications = 64

    private let logger = Logger(subsystem: "com.himmerflow", category: "reconciliation")

    // MARK: - Monitoring degradation (§7.4, §7.5, §9)

    public func effectiveMonitoringTier(
        requested: ShiftPlannerSettings.MonitoringTier,
        locationState: ShiftLocationState
    ) -> ShiftPlannerSettings.MonitoringTier {
        let auth = locationState.locationAuthStatus
        let precise = locationState.accuracyAuthorization == .fullAccuracy

        switch auth {
        case .authorizedAlways:
            return precise ? requested : .manual
        case .authorizedWhenInUse:
            return .manual
        default:
            return .manual
        }
    }

    public func degradationMessage(
        requested: ShiftPlannerSettings.MonitoringTier,
        locationState: ShiftLocationState
    ) -> String? {
        let auth = locationState.locationAuthStatus
        let precise = locationState.accuracyAuthorization == .fullAccuracy

        if auth == .denied || auth == .notDetermined || auth == .restricted {
            return nil
        }
        if !precise {
            return "Precise Location is off — automatic leave/arrival detection unavailable."
        }
        if auth == .authorizedWhenInUse, requested != .manual {
            return "Background location was turned off. Reminders will still work, but automatic departure/arrival detection is paused."
        }
        return nil
    }

    // MARK: - Notification reconciliation (§3)

    public func notificationsToCancel(
        timeline: ShiftTimelineSnapshot?,
        ackState: AcknowledgementState,
        locationState: ShiftLocationState,
        now: Date,
        pendingIDs: [String]
    ) -> [String] {
        guard let timeline else { return pendingIDs }

        var cancelIDs: [String] = []
        let prefix = HimmerFlowNotificationID.shiftPrefix(shiftDate: timeline.primaryAnchor, calendar: calendar)

        for id in pendingIDs where id.hasPrefix(prefix) {
            guard let phase = phaseFromIdentifier(id) else { continue }
            let isBackup = id.hasSuffix(".backup")
            if shouldCancel(
                phase: phase,
                timeline: timeline,
                ackState: ackState,
                locationState: locationState,
                now: now,
                isBackup: isBackup
            ) {
                cancelIDs.append(id)
                logger.info("Notification cancelled: \(id, privacy: .public), reason: reconcile")
            }
        }
        return cancelIDs
    }

    public func shouldCancel(
        phase: ShiftTimelinePhase,
        timeline: ShiftTimelineSnapshot,
        ackState: AcknowledgementState,
        locationState: ShiftLocationState,
        now: Date,
        isBackup: Bool
    ) -> Bool {
        if let window = timeline.window(for: phase), now >= window.end, phase != .shiftEnd {
            return true
        }
        if isBackup, ackState.isAcknowledged(phase) {
            return true
        }
        if isBackup, phase == .leave, locationState.hasConfirmedDeparture {
            return true
        }
        return false
    }

    public func phaseFromIdentifier(_ id: String) -> ShiftTimelinePhase? {
        let parts = id.split(separator: ".")
        guard parts.count >= 4, let raw = Int(parts[parts.count - 2]) else { return nil }
        return ShiftTimelinePhase(rawValue: raw)
    }

    public func remainingScheduleCapacity(currentCount: Int) -> Int {
        max(0, maxNotifications - currentCount)
    }

    // MARK: - Live Activity reconciliation (§8)

    public enum LiveActivityAction: Equatable, Sendable {
        case none
        case start(ShiftActivityContent)
        case update(ShiftActivityContent)
        case end(ShiftActivityContent)
    }

    public func liveActivityAction(
        timeline: ShiftTimelineSnapshot?,
        patternName: String,
        phase: ShiftTimelinePhase,
        now: Date,
        hasActivity: Bool
    ) -> LiveActivityAction {
        guard let timeline else {
            if hasActivity {
                return .end(ShiftActivityContent(
                    shiftName: patternName,
                    clockInTime: now,
                    currentPhase: .idle,
                    nextActionLabel: "Off today",
                    nextActionTime: now,
                    progressFraction: 0,
                    statusEmoji: "😴"
                ))
            }
            return .none
        }

        let content = makeActivityContent(
            timeline: timeline,
            patternName: patternName,
            phase: phase,
            now: now
        )

        if shouldEndLiveActivity(timeline: timeline, now: now) {
            return hasActivity ? .end(content) : .none
        }

        guard shouldStartLiveActivity(phase: phase) else { return .none }
        return hasActivity ? .update(content) : .start(content)
    }

    public func shouldStartLiveActivity(phase: ShiftTimelinePhase) -> Bool {
        phase >= .wake && phase <= .shiftActive
    }

    public func shouldEndLiveActivity(timeline: ShiftTimelineSnapshot, now: Date) -> Bool {
        guard let shiftActive = timeline.window(for: .shiftActive) else { return true }
        let endThreshold = calendar.date(byAdding: DateComponents(minute: 30), to: shiftActive.start) ?? shiftActive.end
        return now >= endThreshold || now >= shiftActive.end
    }

    public func makeActivityContent(
        timeline: ShiftTimelineSnapshot,
        patternName: String,
        phase: ShiftTimelinePhase,
        now: Date
    ) -> ShiftActivityContent {
        let next = timeline.nextTransition(after: now)
        let label: String
        let nextTime: Date
        if let next {
            label = "\(next.phase.displayName) in \(HimmerFlowDateFormatting.relativeHours(until: next.start, from: now))"
            nextTime = next.start
        } else {
            label = phase.displayName
            nextTime = timeline.primaryAnchor
        }

        return ShiftActivityContent(
            shiftName: patternName,
            clockInTime: timeline.primaryAnchor,
            currentPhase: phase,
            nextActionLabel: label,
            nextActionTime: nextTime,
            progressFraction: timeline.progressFraction(at: now),
            statusEmoji: phase.statusEmoji
        )
    }

    // MARK: - Geofence reconciliation (§7)

    public struct MonitoredRegion: Sendable {
        public let location: SavedLocation
        public let identifier: String
        public let notifyOnEntry: Bool
        public let notifyOnExit: Bool
    }

    public func regionsToMonitor(
        home: SavedLocation?,
        work: SavedLocation?,
        tier: ShiftPlannerSettings.MonitoringTier
    ) -> [MonitoredRegion] {
        guard tier != .manual else { return [] }
        var regions: [MonitoredRegion] = []
        if let home {
            regions.append(MonitoredRegion(
                location: home,
                identifier: HimmerFlowRegionID.home,
                notifyOnEntry: true,
                notifyOnExit: true
            ))
        }
        if let work {
            regions.append(MonitoredRegion(
                location: work,
                identifier: HimmerFlowRegionID.work,
                notifyOnEntry: true,
                notifyOnExit: false
            ))
        }
        return regions
    }

    public func circularRegion(
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

    /// Idempotent geofence handler (§7.3). Returns true when state changed.
    @discardableResult
    public mutating func applyGeofenceEvent(
        regionIdentifier: String,
        entering: Bool,
        locationState: inout ShiftLocationState,
        now: Date
    ) -> Bool {
        logger.info(
            "Region event: \(regionIdentifier, privacy: .public), entering: \(entering), timestamp: \(now, privacy: .public)"
        )

        if regionIdentifier == HimmerFlowRegionID.home {
            locationState.isInsideHomeRegion = entering
            if !entering, !locationState.hasConfirmedDeparture {
                locationState.hasConfirmedDeparture = true
                locationState.homeExitTimestamp = now
                logger.info("Confirmed departure via home exit")
                return true
            }
            return false
        }

        if regionIdentifier == HimmerFlowRegionID.work {
            locationState.isInsideWorkRegion = entering
            if entering, !locationState.hasConfirmedArrival {
                locationState.hasConfirmedArrival = true
                locationState.workEntryTimestamp = now
                logger.info("Confirmed arrival via work entry")
                return true
            }
            return false
        }

        return false
    }

    public func shouldUseSignificantChangeMonitoring(
        tier: ShiftPlannerSettings.MonitoringTier,
        locationState: ShiftLocationState
    ) -> Bool {
        tier == .activeCommute
            && locationState.hasConfirmedDeparture
            && !locationState.hasConfirmedArrival
    }

    public func applyInitialRegionState(
        identifier: String,
        state: CLRegionState,
        locationState: inout ShiftLocationState,
        now: Date
    ) {
        if identifier == HimmerFlowRegionID.work, state == .inside, !locationState.hasConfirmedArrival {
            locationState.isInsideWorkRegion = true
            locationState.hasConfirmedArrival = true
            locationState.workEntryTimestamp = now
            logger.info("Confirmed arrival via requestState (already inside work)")
        }
        if identifier == HimmerFlowRegionID.home {
            locationState.isInsideHomeRegion = state == .inside
        }
    }
}
