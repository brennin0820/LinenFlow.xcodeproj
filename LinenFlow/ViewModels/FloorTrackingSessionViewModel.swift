import Foundation
import Observation

@Observable
@MainActor
final class FloorTrackingSessionViewModel {
    private let floorManager: MockFloorTrackingManager
    private let stepManager: MockFootstepTrackingManager
    private let movementCoordinator: MovementSensingCoordinator
    private let calibrationService = FloorHeightCalibrationService()

    private(set) var calibrationState = FloorCalibrationState()

    init() {
        self.floorManager = MockFloorTrackingManager()
        self.stepManager = MockFootstepTrackingManager()
        self.movementCoordinator = MovementSensingCoordinator()
    }

    init(
        floorManager: MockFloorTrackingManager,
        stepManager: MockFootstepTrackingManager,
        movementCoordinator: MovementSensingCoordinator
    ) {
        self.floorManager = floorManager
        self.stepManager = stepManager
        self.movementCoordinator = movementCoordinator
    }

    var floorState: FloorTrackingState { floorManager.currentState }
    var stepState: FootstepTrackingState { stepManager.currentStepState }
    var activeSource: MovementSensingSource { movementCoordinator.activeSource }
    var confidence: MovementConfidence { movementCoordinator.confidence }
    var fallbackReason: String? { movementCoordinator.fallbackReason }
    var isTracking: Bool { floorState.isTracking }
    var currentFloor: Int { floorState.currentFloor }
    var previousFloor: Int? { floorState.previousFloor }
    var direction: FloorDirection { floorState.direction }
    var totalSteps: Int { stepState.totalSteps }
    var currentFloorSteps: Int { stepState.currentFloorSteps }
    var previousFloorSteps: Int { stepState.previousFloorSteps }
    var floorDurations: [FloorDurationRecord] { floorState.floorDurations }
    var stepsByFloor: [FloorStepRecord] { stepState.stepsByFloor }
    var isCalibrated: Bool { calibrationState.isCalibrated }
    var floorHeightMeters: Double { calibrationState.floorHeightMeters }
    var calibrationNote: String? { calibrationState.note }

    var timeOnCurrentFloor: TimeInterval? {
        guard isTracking, let startedAt = floorState.floorStartedAt else { return nil }
        return max(0, Date.now.timeIntervalSince(startedAt))
    }

    var lastFloorDuration: TimeInterval? {
        floorDurations.last?.durationSeconds
    }

    func startTracking(towerName: String, startingFloor: Int) {
        floorManager.startTracking(towerName: towerName, startingFloor: startingFloor)
        stepManager.setCurrentFloor(startingFloor)
        stepManager.startStepTracking()
        movementCoordinator.startTracking()
    }

    func stopTracking() {
        floorManager.stopTracking()
        stepManager.stopStepTracking()
        movementCoordinator.stopTracking()
    }

    func moveUpOneFloor() {
        moveFloor { floorManager.moveUpOneFloor() }
    }

    func moveDownOneFloor() {
        moveFloor { floorManager.moveDownOneFloor() }
    }

    func setCurrentFloor(_ floor: Int) {
        let previous = currentFloor
        if previous != floor {
            stepManager.commitCurrentFloorSteps(floor: previous)
        }
        floorManager.setCurrentFloor(floor)
        stepManager.setCurrentFloor(floorManager.currentState.currentFloor)
    }

    func resetTracking() {
        floorManager.resetTracking()
        stepManager.resetSteps()
        movementCoordinator.reset()
    }

    func startStepTracking() {
        stepManager.setCurrentFloor(currentFloor)
        stepManager.startStepTracking()
    }

    func stopStepTracking() {
        stepManager.stopStepTracking()
    }

    func addStep() {
        stepManager.addManualSteps(1)
    }

    func addTenSteps() {
        stepManager.addManualSteps(10)
    }

    func subtractStep() {
        stepManager.subtractManualSteps(1)
    }

    func resetSteps() {
        stepManager.resetSteps()
        if isTracking {
            stepManager.setCurrentFloor(currentFloor)
            stepManager.startStepTracking()
        }
    }

    func calibrateFloorHeight(towerName: String, verticalDeltaMeters: Double, floorsTraveled: Int) {
        calibrationState = calibrationService.makeCalibration(
            towerName: towerName,
            referenceFloor: currentFloor,
            verticalDeltaMeters: verticalDeltaMeters,
            floorsTraveled: floorsTraveled
        )
    }

    func resetCalibration() {
        calibrationState = FloorCalibrationState()
    }

    func estimatedFloorDelta(verticalDeltaMeters: Double) -> Int? {
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
