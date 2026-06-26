import Foundation

public enum FloorSensingConfidence: String, Hashable, Sendable {
    case unavailable
    case needsCorrection
    case low
    case medium
    case high
}

public struct FloorSensingState: Equatable, Sendable {
    public let isAvailable: Bool
    public let isActive: Bool
    public let towerName: String
    public let startFloor: Int
    public let estimatedFloor: Int
    public let correctedFloor: Int?
    public let baselineAltitudeMeters: Double?
    public let currentRelativeAltitudeMeters: Double?
    public let altitudeDeltaMeters: Double
    public let estimatedFloorDelta: Int
    public let confidence: FloorSensingConfidence
    public let lastUpdatedAt: Date
    public let lastCorrectionAt: Date?
    public let statusMessage: String
}
