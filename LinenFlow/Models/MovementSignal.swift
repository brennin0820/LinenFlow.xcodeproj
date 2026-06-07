import Foundation

struct MovementSignal: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var timestamp: Date
    var source: MovementSensingSource
    var currentFloor: Int?
    var altitudeMeters: Double?
    var verticalDeltaMeters: Double?
    var stepsDelta: Int
    var totalSteps: Int
    var isWalking: Bool
    var isStationary: Bool
    var confidence: MovementConfidence
    var note: String?

    init(
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
