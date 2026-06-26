import Foundation

public enum SmartTipID: String, Hashable, Sendable {
    case towerSeparateSupply
    case towerFloorCount
    case towerFloorCountFormula
    case receivingPhysicalCount
    case bathTowelFixedBin
    case manualPiecesSourceOfTruth
    case optionalPhysicalBins
    case reviewBeforeCalculate
    case bundleFirstDisplay
    case loosePieces
    case resultsMeaning
    case shortage
    case overage
    case floorPlanBasics
    case groupedFloorRanges
    case liveDeliveryOpeningPass
    case logsAreSnapshots
    case logDetailReceipt
    case settingsFutureOnly
    case widgetItemSelection
    case noTowerSelected
    case noItemsEntered
    case invalidNumber
    case saveLogSnapshot
}

public enum SmartTipCategory: String, Hashable, Sendable {
    case tower
    case receiving
    case review
    case bundles
    case results
    case floorPlan
    case liveDelivery
    case logs
    case settings
    case widget
    case validation
}

public enum SmartTipPriority: String, Hashable, Sendable {
    case low
    case normal
    case important
    case warning
}

public struct SmartTip: Identifiable, Hashable, Sendable {
    public let id: SmartTipID
    public let title: String
    public let message: String
    public let category: SmartTipCategory
    public let priority: SmartTipPriority
    public let allowsAutoOpen: Bool
    public let systemImage: String?
    public let actionTitle: String?
}
