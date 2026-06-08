import Foundation

enum PredictionConfidence: String, Codable, Hashable, Sendable {
    case low
    case medium
    case high

    var displayLabel: String {
        switch self {
        case .low: return "Low confidence"
        case .medium: return "Medium confidence"
        case .high: return "High confidence"
        }
    }
}

struct ItemSupplyPrediction: Identifiable, Hashable, Sendable {
    var id: String { itemName }
    let itemName: String
    let predictedPieces: Int?
    let predictedBins: Int?
    let sampleCount: Int
    let sameWeekdaySampleCount: Int
    let confidence: PredictionConfidence
    let typicalLabel: String

    var hasValue: Bool {
        (predictedPieces ?? 0) > 0 || (predictedBins ?? 0) > 0
    }
}

enum SupplyAnomalyDirection: String, Hashable, Sendable {
    case unusuallyLow
    case unusuallyHigh
}

struct SupplyAnomaly: Identifiable, Hashable, Sendable {
    var id: String { itemName }
    let itemName: String
    let enteredValue: Int
    let typicalValue: Int
    let unitLabel: String
    let direction: SupplyAnomalyDirection
    let sampleCount: Int

    var message: String {
        let comparison = direction == .unusuallyLow ? "below" : "above"
        return "\(itemName): \(enteredValue) \(unitLabel) is unusually \(comparison) your typical \(typicalValue) (based on \(sampleCount) past shifts)."
    }
}

enum RecommendationSeverity: String, Hashable, Sendable {
    case info
    case caution
    case action

    var systemImage: String {
        switch self {
        case .info: return "lightbulb.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .action: return "arrow.up.circle.fill"
        }
    }
}

struct SupplyRecommendation: Identifiable, Hashable, Sendable {
    let id: UUID
    let towerName: String?
    let itemName: String?
    let title: String
    let detail: String
    let severity: RecommendationSeverity

    init(
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
