import Foundation

public enum CalculationStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case shortage
    case overage
    case exact

    public var displayName: String {
        switch self {
        case .shortage: return "Shortage"
        case .overage: return "Overage"
        case .exact: return "Exact"
        }
    }
}
