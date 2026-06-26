import Foundation

public struct PlannedFloorPCS: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var floorNumber: Int
    public var itemName: String
    public var plannedPCS: Int
}

public struct FloorRebalanceRequest: Equatable {
    public var itemName: String
    public var originalPCS: Int
    public var totalFloors: Int
    public var originalPlan: [FloorDistributionRow]
    public var shortFloorStart: Int
    public var shortFloorEnd: Int
    public var pcsOnShortFloors: Int
    public var manualOverrideRanges: [FloorRebalanceOverrideRange] = []
}

public struct FloorRebalanceOverrideRange: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var startFloor: Int
    public var endFloor: Int
    public var pcsEach: Int
}

public struct FloorRebalanceTarget: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var floorNumber: Int
    public var currentPCS: Int
    public var targetPCS: Int
    public var delta: Int
}

public enum FloorRebalanceActionType: String, Codable, Equatable {
    case collectBack
    case deliver
    case noChange
}

public struct FloorRebalanceAction: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var startFloor: Int
    public var endFloor: Int
    public var actionType: FloorRebalanceActionType
    public var pcsEach: Int
    public var totalPCS: Int
}

public struct FloorRebalanceResult: Codable, Equatable {
    public var itemName: String
    public var originalPCS: Int
    public var actualPCS: Int
    public var missingPCS: Int
    public var totalFloors: Int
    public var baseTarget: Int
    public var remainder: Int
    public var targets: [FloorRebalanceTarget]
    public var groupedActions: [FloorRebalanceAction]
    public var groupedFinalTargets: [FloorRebalanceAction]
    public var totalCollectBackPCS: Int
    public var totalDeliverPCS: Int
    public var isBalanced: Bool
}
