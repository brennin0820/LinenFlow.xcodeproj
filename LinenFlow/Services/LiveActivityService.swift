import Foundation
import OSLog

#if canImport(ActivityKit)
import ActivityKit
#endif

/// ActivityKit wrapper for shift timeline Live Activities.
/// Start window: wake phase through shiftActive + 30 minutes (enforced by ReconciliationEngine).
final class LiveActivityService: LiveActivityServiceProtocol, @unchecked Sendable {
    var canStartFromBackground: Bool { false }

    func start(initialContent: ShiftActivityContent) async throws -> String {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.disabled
        }

        let attributes = ShiftActivityAttributes(
            shiftName: initialContent.shiftName,
            clockInTime: initialContent.clockInTime
        )
        let state = contentState(from: initialContent)
        let activity = try Activity<ShiftActivityAttributes>.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil),
            pushType: nil
        )
        HimmerFlowLog.liveActivity.info("Started shift activity: \(activity.id, privacy: .public)")
        return activity.id
        #else
        throw LiveActivityError.unavailable
        #endif
    }

    func update(activityID: String, content: ShiftActivityContent) async {
        #if canImport(ActivityKit)
        guard let activity = Activity<ShiftActivityAttributes>.activities.first(where: { $0.id == activityID }) else {
            return
        }
        await activity.update(ActivityContent(state: contentState(from: content), staleDate: nil))
        HimmerFlowLog.liveActivity.debug("Updated shift activity: \(activityID, privacy: .public)")
        #endif
    }

    func end(activityID: String, finalContent: ShiftActivityContent) async {
        #if canImport(ActivityKit)
        guard let activity = Activity<ShiftActivityAttributes>.activities.first(where: { $0.id == activityID }) else {
            return
        }
        await activity.end(
            ActivityContent(state: contentState(from: finalContent), staleDate: nil),
            dismissalPolicy: .default
        )
        HimmerFlowLog.liveActivity.info("Ended shift activity: \(activityID, privacy: .public)")
        #endif
    }

    #if canImport(ActivityKit)
    private func contentState(from content: ShiftActivityContent) -> ShiftActivityAttributes.ContentState {
        ShiftActivityAttributes.ContentState(
            currentPhase: content.currentPhase,
            nextActionLabel: content.nextActionLabel,
            nextActionTime: content.nextActionTime,
            progressFraction: content.progressFraction,
            statusEmoji: content.statusEmoji
        )
    }
    #endif
}

enum LiveActivityError: Error {
    case disabled
    case unavailable
}
