import Foundation
import Observation

@Observable
@MainActor
final class MockFloorTrackingManager: FloorTrackingManager {
    private(set) var currentState: FloorTrackingState

    init() {
        self.currentState = FloorTrackingState()
    }

    init(state: FloorTrackingState) {
        self.currentState = state
    }

    func startTracking(towerName: String, startingFloor: Int) {
        let now = Date.now
        currentState = FloorTrackingState(
            towerName: towerName,
            startingFloor: startingFloor,
            currentFloor: startingFloor,
            direction: .stationary,
            floorStartedAt: now,
            lastFloorChangeAt: now,
            isTracking: true,
            calibrationNote: "Manual simulator-safe tracking. Future real-device floor sensing will use calibrated iPhone altitude plus movement confirmation."
        )
    }

    func stopTracking() {
        guard currentState.isTracking else { return }
        commitCurrentFloorDuration(endedAt: .now)
        currentState.isTracking = false
        currentState.direction = .stationary
    }

    func moveUpOneFloor() {
        setCurrentFloor(currentState.currentFloor + 1)
    }

    func moveDownOneFloor() {
        setCurrentFloor(currentState.currentFloor - 1)
    }

    func setCurrentFloor(_ floor: Int) {
        let now = Date.now
        if !currentState.isTracking {
            currentState.currentFloor = floor
            currentState.startingFloor = floor
            currentState.direction = .stationary
            currentState.floorStartedAt = nil
            return
        }

        let oldFloor = currentState.currentFloor
        guard oldFloor != floor else {
            currentState.direction = .stationary
            return
        }

        commitCurrentFloorDuration(endedAt: now)
        currentState.previousFloor = oldFloor
        currentState.currentFloor = floor
        currentState.direction = floor > oldFloor ? .up : .down
        currentState.floorStartedAt = now
        currentState.lastFloorChangeAt = now
        currentState.totalTrackedFloors += 1
    }

    func resetTracking() {
        currentState = FloorTrackingState()
    }

    private func commitCurrentFloorDuration(endedAt: Date) {
        guard let startedAt = currentState.floorStartedAt else { return }
        currentState.floorDurations.append(
            FloorDurationRecord(
                floorNumber: currentState.currentFloor,
                startedAt: startedAt,
                endedAt: endedAt
            )
        )
    }
}
