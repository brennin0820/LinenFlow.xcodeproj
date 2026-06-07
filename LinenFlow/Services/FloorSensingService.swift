import CoreMotion
import Foundation

@MainActor
final class FloorSensingService {
    private let altimeter = CMAltimeter()
    private var baselineAltitudeMeters: Double?

    var isAvailable: Bool {
        CMAltimeter.isRelativeAltitudeAvailable()
    }

    func start(
        tower: Tower,
        deliveryFloors: [Int],
        startFloor: Int,
        onUpdate: @escaping @MainActor (FloorSensingState) -> Void
    ) {
        stop()

        guard isAvailable else {
            onUpdate(FloorSensingState(
                isAvailable: false,
                isActive: false,
                towerName: tower.name,
                startFloor: startFloor,
                estimatedFloor: startFloor,
                correctedFloor: nil,
                baselineAltitudeMeters: nil,
                currentRelativeAltitudeMeters: nil,
                altitudeDeltaMeters: 0,
                estimatedFloorDelta: 0,
                confidence: .unavailable,
                lastUpdatedAt: .now,
                lastCorrectionAt: nil,
                statusMessage: "This device or simulator does not support relative altitude."
            ))
            return
        }

        let anchoredFloor = FloorSensingEstimator.nearestValidFloor(to: startFloor, in: deliveryFloors)
        onUpdate(FloorSensingState(
            isAvailable: true,
            isActive: true,
            towerName: tower.name,
            startFloor: anchoredFloor,
            estimatedFloor: anchoredFloor,
            correctedFloor: nil,
            baselineAltitudeMeters: nil,
            currentRelativeAltitudeMeters: nil,
            altitudeDeltaMeters: 0,
            estimatedFloorDelta: 0,
            confidence: .low,
            lastUpdatedAt: .now,
            lastCorrectionAt: nil,
            statusMessage: "Waiting for altitude readings."
        ))

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self, towerName = tower.name, floorHeight = tower.estimatedFloorHeightMeters, threshold = tower.floorMovementConfidenceThresholdMeters] data, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    onUpdate(FloorSensingState(
                        isAvailable: true,
                        isActive: false,
                        towerName: towerName,
                        startFloor: anchoredFloor,
                        estimatedFloor: anchoredFloor,
                        correctedFloor: nil,
                        baselineAltitudeMeters: self.baselineAltitudeMeters,
                        currentRelativeAltitudeMeters: nil,
                        altitudeDeltaMeters: 0,
                        estimatedFloorDelta: 0,
                        confidence: .needsCorrection,
                        lastUpdatedAt: .now,
                        lastCorrectionAt: nil,
                        statusMessage: "Floor sensing needs attention: \(error.localizedDescription)"
                    ))
                    return
                }

                guard let data else { return }

                let currentAltitude = data.relativeAltitude.doubleValue
                if self.baselineAltitudeMeters == nil {
                    self.baselineAltitudeMeters = currentAltitude
                }
                let baseline = self.baselineAltitudeMeters ?? currentAltitude
                let altitudeDelta = currentAltitude - baseline
                let estimate = FloorSensingEstimator.estimateFloor(
                    startFloor: anchoredFloor,
                    altitudeDeltaMeters: altitudeDelta,
                    estimatedFloorHeightMeters: floorHeight,
                    movementThresholdMeters: threshold,
                    validFloors: deliveryFloors
                )

                onUpdate(FloorSensingState(
                    isAvailable: true,
                    isActive: true,
                    towerName: towerName,
                    startFloor: anchoredFloor,
                    estimatedFloor: estimate.estimatedFloor,
                    correctedFloor: nil,
                    baselineAltitudeMeters: baseline,
                    currentRelativeAltitudeMeters: currentAltitude,
                    altitudeDeltaMeters: altitudeDelta,
                    estimatedFloorDelta: estimate.floorDelta,
                    confidence: estimate.confidence,
                    lastUpdatedAt: .now,
                    lastCorrectionAt: nil,
                    statusMessage: estimate.statusMessage
                ))
            }
        }
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
        baselineAltitudeMeters = nil
    }

    func correctFloor(
        to floor: Int,
        tower: Tower,
        deliveryFloors: [Int],
        currentRelativeAltitudeMeters: Double?,
        onUpdate: @escaping @MainActor (FloorSensingState) -> Void
    ) {
        let correctedFloor = FloorSensingEstimator.nearestValidFloor(to: floor, in: deliveryFloors)
        if let currentRelativeAltitudeMeters {
            baselineAltitudeMeters = currentRelativeAltitudeMeters
        }

        onUpdate(FloorSensingState(
            isAvailable: isAvailable,
            isActive: isAvailable,
            towerName: tower.name,
            startFloor: correctedFloor,
            estimatedFloor: correctedFloor,
            correctedFloor: correctedFloor,
            baselineAltitudeMeters: baselineAltitudeMeters,
            currentRelativeAltitudeMeters: currentRelativeAltitudeMeters,
            altitudeDeltaMeters: 0,
            estimatedFloorDelta: 0,
            confidence: isAvailable ? .medium : .unavailable,
            lastUpdatedAt: .now,
            lastCorrectionAt: .now,
            statusMessage: isAvailable ? "Corrected floor set as the new sensing start." : "This device or simulator does not support relative altitude."
        ))
    }
}
