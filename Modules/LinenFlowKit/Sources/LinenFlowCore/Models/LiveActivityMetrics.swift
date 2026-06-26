import Foundation

public struct LiveActivityMetrics: Codable, Hashable, Sendable {
    public var towerName: String
    public var currentFloor: Int?
    public var remainingFloorCount: Int
    public var targetDownTime: Date
    public var estimatedFinishTime: Date?
    public var currentTripTitle: String?
}
