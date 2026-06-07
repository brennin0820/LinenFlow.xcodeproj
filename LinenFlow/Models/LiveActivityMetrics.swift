import Foundation

struct LiveActivityMetrics: Codable, Hashable, Sendable {
    var towerName: String
    var currentFloor: Int?
    var remainingFloorCount: Int
    var targetDownTime: Date
    var estimatedFinishTime: Date?
    var currentTripTitle: String?
}
