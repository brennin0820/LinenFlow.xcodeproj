import Foundation

public struct FootstepTrackingState: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var isTracking: Bool
    public var sessionStartedAt: Date?
    public var lastUpdatedAt: Date?
    public var totalSteps: Int
    public var currentFloorSteps: Int
    public var previousFloorSteps: Int
    public var stepsByFloor: [FloorStepRecord]
    public var note: String?

    public var estimatedDistanceFeet: Double {
        Double(totalSteps) * 2.3
    }

    public var estimatedCalories: Double? {
        Double(totalSteps) * 0.04
    }

    public init(
        id: UUID = UUID(),
        isTracking: Bool = false,
        sessionStartedAt: Date? = nil,
        lastUpdatedAt: Date? = nil,
        totalSteps: Int = 0,
        currentFloorSteps: Int = 0,
        previousFloorSteps: Int = 0,
        stepsByFloor: [FloorStepRecord] = [],
        note: String? = nil
    ) {
        self.id = id
        self.isTracking = isTracking
        self.sessionStartedAt = sessionStartedAt
        self.lastUpdatedAt = lastUpdatedAt
        self.totalSteps = max(0, totalSteps)
        self.currentFloorSteps = max(0, currentFloorSteps)
        self.previousFloorSteps = max(0, previousFloorSteps)
        self.stepsByFloor = stepsByFloor
        self.note = note
    }
}
