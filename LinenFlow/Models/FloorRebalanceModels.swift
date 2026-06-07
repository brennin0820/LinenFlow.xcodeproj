import Foundation

struct PlannedFloorPCS: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var floorNumber: Int
    var itemName: String
    var plannedPCS: Int
}

struct FloorRebalanceRequest: Equatable {
    var itemName: String
    var originalPCS: Int
    var totalFloors: Int
    var originalPlan: [FloorDistributionRow]
    var shortFloorStart: Int
    var shortFloorEnd: Int
    var pcsOnShortFloors: Int
    var manualOverrideRanges: [FloorRebalanceOverrideRange] = []
}

struct FloorRebalanceOverrideRange: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var startFloor: Int
    var endFloor: Int
    var pcsEach: Int
}

struct FloorRebalanceTarget: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var floorNumber: Int
    var currentPCS: Int
    var targetPCS: Int
    var delta: Int
}

enum FloorRebalanceActionType: String, Codable, Equatable {
    case collectBack
    case deliver
    case noChange
}

struct FloorRebalanceAction: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var startFloor: Int
    var endFloor: Int
    var actionType: FloorRebalanceActionType
    var pcsEach: Int
    var totalPCS: Int
}

struct FloorRebalanceResult: Codable, Equatable {
    var itemName: String
    var originalPCS: Int
    var actualPCS: Int
    var missingPCS: Int
    var totalFloors: Int
    var baseTarget: Int
    var remainder: Int
    var targets: [FloorRebalanceTarget]
    var groupedActions: [FloorRebalanceAction]
    var groupedFinalTargets: [FloorRebalanceAction]
    var totalCollectBackPCS: Int
    var totalDeliverPCS: Int
    var isBalanced: Bool
}
