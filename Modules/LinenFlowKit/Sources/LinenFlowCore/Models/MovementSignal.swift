import Foundation

public struct MovementSignal: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var source: MovementSensingSource
    public var currentFloor: Int?
    public var altitudeMeters: Double?
    public var verticalDeltaMeters: Double?
    public var stepsDelta: Int
    public var totalSteps: Int
    public var isWalking: Bool
    public var isStationary: Bool
    public var confidence: MovementConfidence
    public var note: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        source: MovementSensingSource = .manualOnly,
        currentFloor: Int? = nil,
        altitudeMeters: Double? = nil,
        verticalDeltaMeters: Double? = nil,
        stepsDelta: Int = 0,
        totalSteps: Int = 0,
        isWalking: Bool = false,
        isStationary: Bool = true,
        confidence: MovementConfidence = .low,
        note: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.currentFloor = currentFloor
        self.altitudeMeters = altitudeMeters
        self.verticalDeltaMeters = verticalDeltaMeters
        self.stepsDelta = max(0, stepsDelta)
        self.totalSteps = max(0, totalSteps)
        self.isWalking = isWalking
        self.isStationary = isStationary
        self.confidence = confidence
        self.note = note
    }
}
