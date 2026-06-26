import Foundation
import LinenFlowCore
import LinenFlowEngine

/// Legacy wizard navigation steps (archived — excluded from app target).
public enum FlowStep: Hashable {
    case receiving
    case review
    case results
    case floorPlan
    case rebalance(itemName: String?)
}
