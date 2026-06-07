import Foundation

#if canImport(ActivityKit)
import ActivityKit

@MainActor
enum LiveActivityManager {
    static func startDeliveryActivity(
        towerName: String,
        floorCount: Int,
        towerColorHex: String?,
        state: DeliverySessionState
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if let activity = activeActivity {
            Task {
                await activity.update(ActivityContent(state: contentState(from: state), staleDate: nil))
            }
            return
        }

        let attributes = HimmerFlowDeliveryAttributes(
            towerName: towerName,
            floorCount: floorCount,
            towerColorHex: towerColorHex
        )

        do {
            _ = try Activity<HimmerFlowDeliveryAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: contentState(from: state), staleDate: nil),
                pushType: nil
            )
        } catch {
            return
        }
    }

    static func updateDeliveryActivity(state: DeliverySessionState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, let activity = activeActivity else { return }
        Task {
            await activity.update(ActivityContent(state: contentState(from: state), staleDate: nil))
        }
    }

    static func endDeliveryActivity(state: DeliverySessionState) {
        guard let activity = activeActivity else { return }
        Task {
            await activity.end(ActivityContent(state: contentState(from: state), staleDate: nil), dismissalPolicy: .default)
        }
    }

    static func startDeliveryActivity(from state: SharedWidgetState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if let activity = activeActivity {
            Task {
                await activity.update(ActivityContent(state: contentState(from: state), staleDate: nil))
            }
            return
        }

        let attributes = HimmerFlowDeliveryAttributes(
            towerName: state.towerName,
            floorCount: state.floorCount,
            towerColorHex: state.towerColorHex
        )

        do {
            _ = try Activity<HimmerFlowDeliveryAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: contentState(from: state), staleDate: nil),
                pushType: nil
            )
        } catch {
            return
        }
    }

    static func updateDeliveryActivity(from state: SharedWidgetState) {
        guard let activity = activeActivity else { return }
        Task {
            await activity.update(ActivityContent(state: contentState(from: state), staleDate: nil))
        }
    }

    static func endDeliveryActivity() {
        guard let activity = activeActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .default)
        }
    }

    static func endAllActivities() {
        for activity in Activity<HimmerFlowDeliveryAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private static var activeActivity: Activity<HimmerFlowDeliveryAttributes>? {
        Activity<HimmerFlowDeliveryAttributes>.activities.first
    }

    private static func contentState(from state: SharedWidgetState) -> HimmerFlowDeliveryAttributes.ContentState {
        HimmerFlowDeliveryAttributes.ContentState(
            completedFloors: state.completedFloors,
            remainingFloors: state.remainingFloors,
            currentItemName: state.currentItemName,
            currentItemNames: state.currentItemNames,
            currentTripItemNames: state.currentTripItemNames,
            currentFloorNumber: state.currentFloorNumber,
            currentFloorDeliveryAmounts: state.currentFloorDeliveryAmounts,
            currentTripRemainingBundles: state.currentTripRemainingBundles,
            currentTripTotalBundles: state.currentTripTotalBundles,
            nextCarryGroupTitle: state.nextCarryGroupTitle,
            statusText: state.statusText,
            targetTime: state.targetTime,
            lastUpdated: state.lastUpdated,
            isActiveSession: state.isActiveSession
        )
    }

    private static func contentState(from state: DeliverySessionState) -> HimmerFlowDeliveryAttributes.ContentState {
        HimmerFlowDeliveryAttributes.ContentState(
            completedFloors: state.completedCount,
            remainingFloors: state.remainingCount,
            currentItemName: state.currentItemName,
            currentItemNames: [state.currentItemName].compactMap { $0 },
            currentTripItemNames: [state.currentItemName].compactMap { $0 },
            currentFloorNumber: state.deliveryFloors.first(where: { !state.completedFloorNumbers.contains($0) }),
            currentFloorDeliveryAmounts: nil,
            currentTripRemainingBundles: nil,
            currentTripTotalBundles: nil,
            nextCarryGroupTitle: state.nextCarryGroupTitle,
            statusText: deliveryStatusText(for: state),
            targetTime: nil,
            lastUpdated: .now,
            isActiveSession: state.isActive && !state.isPaused
        )
    }

    private static func deliveryStatusText(for state: DeliverySessionState) -> String {
        if state.isComplete { return "Delivery complete" }
        if state.isPaused { return "Delivery paused" }
        if state.isActive { return "\(state.completedCount)/\(state.floorCount) floors complete" }
        return "Delivery ready"
    }
}
#else
@MainActor
enum LiveActivityManager {
    static func startDeliveryActivity(towerName: String, floorCount: Int, towerColorHex: String?, state: DeliverySessionState) {}
    static func updateDeliveryActivity(state: DeliverySessionState) {}
    static func endDeliveryActivity(state: DeliverySessionState) {}
    static func startDeliveryActivity(from state: SharedWidgetState) {}
    static func updateDeliveryActivity(from state: SharedWidgetState) {}
    static func endDeliveryActivity() {}
    static func endAllActivities() {}
}
#endif
