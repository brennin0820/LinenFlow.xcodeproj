import Foundation

enum FloorSensingConfidence: String, Hashable, Sendable {
    case unavailable
    case needsCorrection
    case low
    case medium
    case high
}

struct FloorSensingState: Equatable, Sendable {
    let isAvailable: Bool
    let isActive: Bool
    let towerName: String
    let startFloor: Int
    let estimatedFloor: Int
    let correctedFloor: Int?
    let baselineAltitudeMeters: Double?
    let currentRelativeAltitudeMeters: Double?
    let altitudeDeltaMeters: Double
    let estimatedFloorDelta: Int
    let confidence: FloorSensingConfidence
    let lastUpdatedAt: Date
    let lastCorrectionAt: Date?
    let statusMessage: String
}
