import Foundation
import LinenFlowCore

// MARK: - Tower Calibration Service
// Centralizes tower-specific floor height math to support future barometer-based floor detection.
// No sensors are activated here; all functions are pure computation on stored calibration values.
//
// False floor change protection (future implementation):
// "Floor changes should require sustained vertical movement and stabilized altitude before confirmation."
// Guard against: elevator vibration, stair vs. ramp ambiguity, body lean, temporary altitude drift,
// HVAC pressure changes, and phone repositioning artifacts.
//
// Sensor fusion roles (future):
// - Apple Watch: body movement, wrist motion, walking confirmation, step confirmation
// - iPhone: barometer altitude, vertical movement, UI confirmation, manual override
// - Manual controls: remain available for reliability; override automatic estimates when needed
//
// Performance & battery (future):
// - Avoid aggressive altitude polling; reduce update rate while stationary.
// - Use throttled updates and avoid unnecessary background work.
public enum TowerCalibrationService {
    private static let fallbackFloorHeightMeters: Double = 3.1

    /// Calibrated floor height for a tower, falling back to 3.1 m if the stored value is invalid.
    public static func estimatedFloorHeight(for tower: Tower) -> Double {
        let h = tower.estimatedFloorHeightMeters
        return h > 0 ? h : fallbackFloorHeightMeters
    }

    /// Estimates the number of floors corresponding to a raw altitude delta.
    /// Uses standard rounding so a half-floor rounds to the nearest integer.
    public static func floorEstimate(altitudeDeltaMeters: Double, tower: Tower) -> Int {
        let height = estimatedFloorHeight(for: tower)
        return Int((altitudeDeltaMeters / height).rounded())
    }

    /// Returns true when the altitude delta exceeds the tower's minimum movement threshold.
    /// Movements below this value are treated as sensor noise and ignored.
    public static func isValidFloorMovement(altitudeDeltaMeters: Double, tower: Tower) -> Bool {
        abs(altitudeDeltaMeters) >= tower.floorMovementConfidenceThresholdMeters
    }

    /// Returns a 0–1 confidence score for a proposed floor change.
    /// 1.0 means the delta aligns perfectly with an integer multiple of the floor height;
    /// values decay toward 0 as the deviation approaches the tolerance window.
    public static func floorChangeConfidence(altitudeDeltaMeters: Double, tower: Tower) -> Double {
        let height = estimatedFloorHeight(for: tower)
        guard height > 0,
              abs(altitudeDeltaMeters) >= tower.floorMovementConfidenceThresholdMeters else {
            return 0
        }
        let ratio = altitudeDeltaMeters / height
        let nearest = ratio.rounded()
        guard nearest != 0 else { return 0 }
        let deviation = abs(ratio - nearest)
        let toleranceFraction = tower.floorDetectionToleranceMeters / height
        return max(0, 1.0 - (deviation / toleranceFraction))
    }
}
