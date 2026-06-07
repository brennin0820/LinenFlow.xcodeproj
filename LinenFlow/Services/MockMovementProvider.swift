import Foundation
import Observation

@Observable
@MainActor
final class MockMovementProvider: MovementProvider {
    let source: MovementSensingSource = .manualOnly
    private(set) var latestSignal: MovementSignal?
    private(set) var confidence: MovementConfidence = .low
    private(set) var isAvailable: Bool = true
    private(set) var unavailableReason: String? = nil

    func start() {
        latestSignal = MovementSignal(
            source: .manualOnly,
            isWalking: false,
            isStationary: true,
            confidence: .low,
            note: "Manual fallback active for simulator-safe floor and step tracking."
        )
    }

    func stop() {
        latestSignal = MovementSignal(
            source: .manualOnly,
            isWalking: false,
            isStationary: true,
            confidence: .low,
            note: "Manual fallback stopped."
        )
    }

    func reset() {
        latestSignal = nil
    }

    func emitManualSignal(currentFloor: Int?, stepsDelta: Int, totalSteps: Int, note: String? = nil) {
        latestSignal = MovementSignal(
            source: .manualOnly,
            currentFloor: currentFloor,
            stepsDelta: max(0, stepsDelta),
            totalSteps: max(0, totalSteps),
            isWalking: stepsDelta > 0,
            isStationary: stepsDelta == 0,
            confidence: .low,
            note: note ?? "Manual movement signal."
        )
    }
}
