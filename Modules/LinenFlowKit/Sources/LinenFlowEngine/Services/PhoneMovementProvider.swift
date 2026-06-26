import Foundation
import Observation
import LinenFlowCore

@Observable
@MainActor
public final class PhoneMovementProvider: MovementProvider {
    public let source: MovementSensingSource = .phoneOnly
    private(set) var latestSignal: MovementSignal?
    private(set) var confidence: MovementConfidence = .low
    private(set) var isAvailable: Bool = false
    private(set) var unavailableReason: String? = "Phone live sensing is prepared but disabled until real-device calibration is added."

    public func start() {
        latestSignal = MovementSignal(
            source: .phoneOnly,
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
 Future phone movement provider notes:
 - CMAltimeter can estimate vertical movement on supported real devices.
 - CMPedometer can provide iPhone step deltas when the phone is carried.
 - CMMotionActivityManager can help distinguish walking, stationary, elevator, and vehicle-like motion.
 - Floor height calibration must be tower-specific and real-device tested.
 - Simulator builds must keep this provider inactive until live sensor work is explicitly enabled.

 Landed Floor = vertical movement stopped and altitude stabilized.
 Worked Floor = landed floor plus steps or dwell time.
 Delivered Floor = user-confirmed delivery checklist state.

 Apple Watch helps confirm body movement and steps.
 iPhone barometer helps estimate vertical movement.
 Manual confirmation remains required for reliability.
 */
