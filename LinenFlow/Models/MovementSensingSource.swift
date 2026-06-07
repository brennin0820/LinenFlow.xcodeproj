import Foundation

enum MovementSensingSource: String, Codable, Sendable {
    case watchAndPhone
    case phoneOnly
    case manualOnly

    var displayName: String {
        switch self {
        case .watchAndPhone: return "Watch + iPhone"
        case .phoneOnly: return "iPhone Only"
        case .manualOnly: return "Manual Only"
        }
    }
}

enum MovementConfidence: String, Codable, Sendable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}
