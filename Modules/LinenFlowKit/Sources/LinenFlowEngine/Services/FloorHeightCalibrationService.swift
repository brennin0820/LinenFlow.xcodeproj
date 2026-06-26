import Foundation
import LinenFlowCore

public struct FloorHeightCalibrationService: Sendable {
    private let minimumFloorHeightMeters = 2.4
    private let maximumFloorHeightMeters = 5.0

    public func makeCalibration(
        towerName: String,
        referenceFloor: Int,
        verticalDeltaMeters: Double,
        floorsTraveled: Int
    ) -> FloorCalibrationState {
        let safeFloors = max(1, abs(floorsTraveled))
        let rawHeight = abs(verticalDeltaMeters) / Double(safeFloors)
        let clampedHeight = min(max(rawHeight, minimumFloorHeightMeters), maximumFloorHeightMeters)
        let note: String

        if rawHeight < minimumFloorHeightMeters || rawHeight > maximumFloorHeightMeters {
            note = "Calibration saved with a protected floor-height range. Recalibrate on a real device if this looks off."
        } else {
            note = "Real-device floor height calibrated. Manual confirmation remains required for delivery accuracy."
        }

        return FloorCalibrationState(
            towerName: towerName,
            referenceFloor: referenceFloor,
            floorHeightMeters: clampedHeight,
            verticalDeltaMeters: verticalDeltaMeters,
            floorsMeasured: safeFloors,
            calibratedAt: .now,
            isCalibrated: true,
            note: note
        )
    }

    public func estimatedFloorDelta(verticalDeltaMeters: Double, calibration: FloorCalibrationState) -> Int? {
        guard calibration.isCalibrated, calibration.floorHeightMeters > 0 else { return nil }
        let delta = verticalDeltaMeters / calibration.floorHeightMeters
        return Int(delta.rounded())
    }
}

/*
 Real-device calibration design:
 - A real iPhone barometer can estimate vertical delta, but each tower needs a calibrated floor height.
 - Calibration should be taken from a known floor movement, such as floor 4 to floor 5.
 - Manual confirmation remains required before marking any floor delivered.
 - This service is pure and simulator-safe; live CMAltimeter wiring belongs in PhoneMovementProvider later.
 */
