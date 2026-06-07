import Foundation

enum SmartTipID: String, Hashable, Sendable {
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

enum SmartTipCategory: String, Hashable, Sendable {
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

enum SmartTipPriority: String, Hashable, Sendable {
    case low
    case normal
    case important
    case warning
}

struct SmartTip: Identifiable, Hashable, Sendable {
    let id: SmartTipID
    let title: String
    let message: String
    let category: SmartTipCategory
    let priority: SmartTipPriority
    let allowsAutoOpen: Bool
    let systemImage: String?
    let actionTitle: String?
}
