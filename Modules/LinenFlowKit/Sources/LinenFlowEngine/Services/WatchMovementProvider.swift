import Foundation
import Observation
import LinenFlowCore

@Observable
@MainActor
public final class WatchMovementProvider: MovementProvider {
    public let source: MovementSensingSource = .watchAndPhone
    private(set) var latestSignal: MovementSignal?
    private(set) var confidence: MovementConfidence = .low
    private(set) var isAvailable: Bool = false
    private(set) var unavailableReason: String? = "Apple Watch companion sensing is not installed. Using iPhone/manual fallback."

    public func start() {
        latestSignal = MovementSignal(
            source: .watchAndPhone,
            isWalking: false,
            isStationary: true,
            confidence: .low,
            note: unavailableReason
        )
    }

    public func stop() { }

    public func reset() {
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
