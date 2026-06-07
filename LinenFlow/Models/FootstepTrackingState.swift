import Foundation

struct FootstepTrackingState: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var isTracking: Bool
    var sessionStartedAt: Date?
    var lastUpdatedAt: Date?
    var totalSteps: Int
    var currentFloorSteps: Int
    var previousFloorSteps: Int
    var stepsByFloor: [FloorStepRecord]
    var note: String?

    var estimatedDistanceFeet: Double {
        Double(totalSteps) * 2.3
    }

    var estimatedCalories: Double? {
        Double(totalSteps) * 0.04
    }

    init(
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
