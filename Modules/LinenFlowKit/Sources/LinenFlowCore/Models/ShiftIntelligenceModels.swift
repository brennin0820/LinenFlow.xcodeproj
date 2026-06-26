import Foundation

public enum PredictionConfidence: String, Codable, Hashable, Sendable {
    case low
    case medium
    case high

    public var displayLabel: String {
        switch self {
        case .low: return "Low confidence"
        case .medium: return "Medium confidence"
        case .high: return "High confidence"
        }
    }
}

public struct ItemSupplyPrediction: Identifiable, Hashable, Sendable {
    public var id: String { itemName }
    public let itemName: String
    public let predictedPieces: Int?
    public let predictedBins: Int?
    public let sampleCount: Int
    public let sameWeekdaySampleCount: Int
    public let confidence: PredictionConfidence
    public let typicalLabel: String

    public var hasValue: Bool {
        (predictedPieces ?? 0) > 0 || (predictedBins ?? 0) > 0
    }
}

public enum SupplyAnomalyDirection: String, Hashable, Sendable {
    case unusuallyLow
    case unusuallyHigh
}

public struct SupplyAnomaly: Identifiable, Hashable, Sendable {
    public var id: String { itemName }
    public let itemName: String
    public let enteredValue: Int
    public let typicalValue: Int
    public let unitLabel: String
    public let direction: SupplyAnomalyDirection
    public let sampleCount: Int

    public var message: String {
        let comparison = direction == .unusuallyLow ? "below" : "above"
        return "\(itemName): \(enteredValue) \(unitLabel) is unusually \(comparison) your typical \(typicalValue) (based on \(sampleCount) past shifts)."
    }
}

public enum RecommendationSeverity: String, Hashable, Sendable {
    case info
    case caution
    case action

    public var systemImage: String {
        switch self {
        case .info: return "lightbulb.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .action: return "arrow.up.circle.fill"
        }
    }
}

public struct SupplyRecommendation: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let towerName: String?
    public let itemName: String?
    public let title: String
    public let detail: String
    public let severity: RecommendationSeverity

    public init(
        id: UUID = UUID(),
        towerName: String?,
        itemName: String?,
        title: String,
        detail: String,
        severity: RecommendationSeverity
    ) {
        self.id = id
        self.towerName = towerName
        self.itemName = itemName
        self.title = title
        self.detail = detail
        self.severity = severity
    }
}
