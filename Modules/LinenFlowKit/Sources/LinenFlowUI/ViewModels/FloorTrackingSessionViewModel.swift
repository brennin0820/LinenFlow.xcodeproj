import Foundation
import Observation
import LinenFlowCore
import LinenFlowEngine

@Observable
@MainActor
public final class FloorTrackingSessionViewModel {
    private let floorManager: MockFloorTrackingManager
    private let stepManager: MockFootstepTrackingManager
    private let movementCoordinator: MovementSensingCoordinator
    private let calibrationService = FloorHeightCalibrationService()

    private(set) var calibrationState = FloorCalibrationState()

    public init() {
        self.floorManager = MockFloorTrackingManager()
        self.stepManager = MockFootstepTrackingManager()
        self.movementCoordinator = MovementSensingCoordinator()
    }

    public init(
        floorManager: MockFloorTrackingManager,
        stepManager: MockFootstepTrackingManager,
        movementCoordinator: MovementSensingCoordinator
    ) {
        self.floorManager = floorManager
        self.stepManager = stepManager
        self.movementCoordinator = movementCoordinator
    }

    public var floorState: FloorTrackingState { floorManager.currentState }
    public var stepState: FootstepTrackingState { stepManager.currentStepState }
    public var activeSource: MovementSensingSource { movementCoordinator.activeSource }
    public var confidence: MovementConfidence { movementCoordinator.confidence }
    public var fallbackReason: String? { movementCoordinator.fallbackReason }
    public var isTracking: Bool { floorState.isTracking }
    public var currentFloor: Int { floorState.currentFloor }
    public var previousFloor: Int? { floorState.previousFloor }
    public var direction: FloorDirection { floorState.direction }
    public var totalSteps: Int { stepState.totalSteps }
    public var currentFloorSteps: Int { stepState.currentFloorSteps }
    public var previousFloorSteps: Int { stepState.previousFloorSteps }
    public var floorDurations: [FloorDurationRecord] { floorState.floorDurations }
    public var stepsByFloor: [FloorStepRecord] { stepState.stepsByFloor }
    public var isCalibrated: Bool { calibrationState.isCalibrated }
    public var floorHeightMeters: Double { calibrationState.floorHeightMeters }
    public var calibrationNote: String? { calibrationState.note }

    public var timeOnCurrentFloor: TimeInterval? {
        guard isTracking, let startedAt = floorState.floorStartedAt else { return nil }
        return max(0, Date.now.timeIntervalSince(startedAt))
    }

    public var lastFloorDuration: TimeInterval? {
        floorDurations.last?.durationSeconds
    }

    public func startTracking(towerName: String, startingFloor: Int) {
        floorManager.startTracking(towerName: towerName, startingFloor: startingFloor)
        stepManager.setCurrentFloor(startingFloor)
        stepManager.startStepTracking()
        movementCoordinator.startTracking()
    }

    public func stopTracking() {
        floorManager.stopTracking()
        stepManager.stopStepTracking()
        movementCoordinator.stopTracking()
    }

    public func moveUpOneFloor() {
        moveFloor { floorManager.moveUpOneFloor() }
    }

    public func moveDownOneFloor() {
        moveFloor { floorManager.moveDownOneFloor() }
    }

    public func setCurrentFloor(_ floor: Int) {
        let previous = currentFloor
        if previous != floor {
            stepManager.commitCurrentFloorSteps(floor: previous)
        }
        floorManager.setCurrentFloor(floor)
        stepManager.setCurrentFloor(floorManager.currentState.currentFloor)
    }

    public func resetTracking() {
        floorManager.resetTracking()
        stepManager.resetSteps()
        movementCoordinator.reset()
    }

    public func startStepTracking() {
        stepManager.setCurrentFloor(currentFloor)
        stepManager.startStepTracking()
    }

    public func stopStepTracking() {
        stepManager.stopStepTracking()
    }

    public func addStep() {
        stepManager.addManualSteps(1)
    }

    public func addTenSteps() {
        stepManager.addManualSteps(10)
    }

    public func subtractStep() {
        stepManager.subtractManualSteps(1)
    }

    public func resetSteps() {
        stepManager.resetSteps()
        if isTracking {
            stepManager.setCurrentFloor(currentFloor)
            stepManager.startStepTracking()
        }
    }

    public func calibrateFloorHeight(towerName: String, verticalDeltaMeters: Double, floorsTraveled: Int) {
        calibrationState = calibrationService.makeCalibration(
            towerName: towerName,
            referenceFloor: currentFloor,
            verticalDeltaMeters: verticalDeltaMeters,
            floorsTraveled: floorsTraveled
        )
    }

    public func resetCalibration() {
        calibrationState = FloorCalibrationState()
    }

    public func estimatedFloorDelta(verticalDeltaMeters: Double) -> Int? {
        calibrationService.estimatedFloorDelta(
            verticalDeltaMeters: verticalDeltaMeters,
            calibration: calibrationState
        )
    }

    private func moveFloor(_ movement: () -> Void) {
        let previous = currentFloor
        stepManager.commitCurrentFloorSteps(floor: previous)
        movement()
        stepManager.setCurrentFloor(floorManager.currentState.currentFloor)
    }
}
