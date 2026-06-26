import Foundation

public enum MovementSensingSource: String, Codable, Sendable {
    case watchAndPhone
    case phoneOnly
    case manualOnly

    public var displayName: String {
        switch self {
        case .watchAndPhone: return "Watch + iPhone"
        case .phoneOnly: return "iPhone Only"
        case .manualOnly: return "Manual Only"
        }
    }
}

public enum MovementConfidence: String, Codable, Sendable {
    case low
    case medium
    case high

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}
