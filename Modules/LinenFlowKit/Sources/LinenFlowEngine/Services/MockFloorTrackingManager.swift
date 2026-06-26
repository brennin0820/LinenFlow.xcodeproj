import Foundation
import Observation
import LinenFlowCore

@Observable
@MainActor
public final class MockFloorTrackingManager: FloorTrackingManager {
    private(set) var currentState: FloorTrackingState

    public init() {
        self.currentState = FloorTrackingState()
    }

    public init(state: FloorTrackingState) {
        self.currentState = state
    }

    public func startTracking(towerName: String, startingFloor: Int) {
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

    public func stopTracking() {
        guard currentState.isTracking else { return }
        commitCurrentFloorDuration(endedAt: .now)
        currentState.isTracking = false
        currentState.direction = .stationary
    }

    public func moveUpOneFloor() {
        setCurrentFloor(currentState.currentFloor + 1)
    }

    public func moveDownOneFloor() {
        setCurrentFloor(currentState.currentFloor - 1)
    }

    public func setCurrentFloor(_ floor: Int) {
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

    public func resetTracking() {
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
