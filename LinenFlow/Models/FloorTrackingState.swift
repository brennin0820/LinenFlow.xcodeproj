import Foundation

enum FloorDirection: String, Codable, Sendable {
    case up
    case down
    case stationary
    case unknown

    var displayName: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        case .stationary: return "Stationary"
        case .unknown: return "Unknown"
        }
    }
}

struct FloorTrackingState: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var towerName: String
    var startingFloor: Int
    var currentFloor: Int
    var previousFloor: Int?
    var direction: FloorDirection
    var floorStartedAt: Date?
    var lastFloorChangeAt: Date?
    var floorDurations: [FloorDurationRecord]
    var totalTrackedFloors: Int
    var isTracking: Bool
    var calibrationNote: String?

    init(
        id: UUID = UUID(),
        towerName: String = "",
        startingFloor: Int = 0,
        currentFloor: Int = 0,
        previousFloor: Int? = nil,
        direction: FloorDirection = .unknown,
        floorStartedAt: Date? = nil,
        lastFloorChangeAt: Date? = nil,
        floorDurations: [FloorDurationRecord] = [],
        totalTrackedFloors: Int = 0,
        isTracking: Bool = false,
        calibrationNote: String? = nil
    ) {
        self.id = id
        self.towerName = towerName
        self.startingFloor = startingFloor
        self.currentFloor = currentFloor
        self.previousFloor = previousFloor
        self.direction = direction
        self.floorStartedAt = floorStartedAt
        self.lastFloorChangeAt = lastFloorChangeAt
        self.floorDurations = floorDurations
        self.totalTrackedFloors = totalTrackedFloors
        self.isTracking = isTracking
        self.calibrationNote = calibrationNote
    }
}
