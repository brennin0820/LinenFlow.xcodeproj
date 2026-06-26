import Foundation

public enum FloorDirection: String, Codable, Sendable {
    case up
    case down
    case stationary
    case unknown

    public var displayName: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        case .stationary: return "Stationary"
        case .unknown: return "Unknown"
        }
    }
}

public struct FloorTrackingState: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var towerName: String
    public var startingFloor: Int
    public var currentFloor: Int
    public var previousFloor: Int?
    public var direction: FloorDirection
    public var floorStartedAt: Date?
    public var lastFloorChangeAt: Date?
    public var floorDurations: [FloorDurationRecord]
    public var totalTrackedFloors: Int
    public var isTracking: Bool
    public var calibrationNote: String?

    public init(
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
