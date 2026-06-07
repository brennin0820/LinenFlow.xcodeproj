import Foundation
import Observation

@Observable
@MainActor
final class WatchMovementProvider: MovementProvider {
    let source: MovementSensingSource = .watchAndPhone
    private(set) var latestSignal: MovementSignal?
    private(set) var confidence: MovementConfidence = .low
    private(set) var isAvailable: Bool = false
    private(set) var unavailableReason: String? = "Apple Watch companion sensing is not installed. Using iPhone/manual fallback."

    func start() {
        latestSignal = MovementSignal(
            source: .watchAndPhone,
            isWalking: false,
            isStationary: true,
            confidence: .low,
            note: unavailableReason
        )
    }

    func stop() { }

    func reset() {
        latestSignal = nil
    }
}

/*
 Future Apple Watch provider notes:
 - WatchConnectivity can move compact movement deltas from a companion app to iPhone.
 - A watch companion app can collect wrist movement, workout session state, and watch step count.
 - Wrist movement should be synchronized with iPhone floor/altitude estimates, not used alone.
 - Workout sessions may improve live motion reliability during active delivery periods.
 - No watchOS target or WatchConnectivity dependency is required for this foundation.
 */
