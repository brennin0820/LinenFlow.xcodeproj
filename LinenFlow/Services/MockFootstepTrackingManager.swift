import Foundation
import Observation

@Observable
@MainActor
final class MockFootstepTrackingManager: FootstepTrackingManager {
    private(set) var currentStepState: FootstepTrackingState
    private var activeFloor: Int?

    init() {
        self.currentStepState = FootstepTrackingState()
    }

    init(state: FootstepTrackingState) {
        self.currentStepState = state
    }

    func startStepTracking() {
        let now = Date.now
        currentStepState.isTracking = true
        currentStepState.sessionStartedAt = currentStepState.sessionStartedAt ?? now
        currentStepState.lastUpdatedAt = now
        currentStepState.note = "Manual step tracking is active. Future versions can reconcile iPhone and Apple Watch step deltas."
    }

    func stopStepTracking() {
        currentStepState.isTracking = false
        currentStepState.lastUpdatedAt = .now
    }

    func resetSteps() {
        currentStepState = FootstepTrackingState()
        activeFloor = nil
    }

    func addManualSteps(_ count: Int) {
        let safeCount = max(0, count)
        guard safeCount > 0 else { return }
        currentStepState.totalSteps += safeCount
        currentStepState.currentFloorSteps += safeCount
        currentStepState.lastUpdatedAt = .now
    }

    func subtractManualSteps(_ count: Int) {
        let safeCount = max(0, count)
        guard safeCount > 0 else { return }
        let removableFromCurrent = min(currentStepState.currentFloorSteps, safeCount)
        currentStepState.currentFloorSteps -= removableFromCurrent
        currentStepState.totalSteps = max(0, currentStepState.totalSteps - removableFromCurrent)
        currentStepState.lastUpdatedAt = .now
    }

    func setCurrentFloor(_ floor: Int) {
        if let activeFloor, activeFloor != floor {
            commitCurrentFloorSteps(floor: activeFloor)
        }
        activeFloor = floor
    }

    func commitCurrentFloorSteps(floor: Int) {
        let steps = max(0, currentStepState.currentFloorSteps)
        currentStepState.previousFloorSteps = steps
        upsertRecord(floor: floor, steps: steps)
        currentStepState.currentFloorSteps = 0
        currentStepState.lastUpdatedAt = .now
        activeFloor = floor
    }

    private func upsertRecord(floor: Int, steps: Int) {
        guard steps > 0 else { return }
        if let index = currentStepState.stepsByFloor.firstIndex(where: { $0.floorNumber == floor }) {
            currentStepState.stepsByFloor[index].steps += steps
            currentStepState.stepsByFloor[index].updatedAt = .now
        } else {
            currentStepState.stepsByFloor.append(FloorStepRecord(floorNumber: floor, steps: steps))
            currentStepState.stepsByFloor.sort { $0.floorNumber < $1.floorNumber }
        }
    }
}
