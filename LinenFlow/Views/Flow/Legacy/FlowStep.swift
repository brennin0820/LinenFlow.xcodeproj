import Foundation

/// Legacy wizard navigation steps (archived — excluded from app target).
enum FlowStep: Hashable {
    case receiving
    case review
    case results
    case floorPlan
    case rebalance(itemName: String?)
}
