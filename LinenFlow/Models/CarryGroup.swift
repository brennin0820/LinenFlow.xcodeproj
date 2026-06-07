import Foundation

struct CarryGroup: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var itemName: String
    var label: String
    var carryType: CarryType
    var count: Int
    var estimatedWeightClass: EstimatedWeightClass
    var sourceEntryID: UUID?

    init(
        id: UUID = UUID(),
        itemName: String,
        label: String,
        carryType: CarryType,
        count: Int,
        estimatedWeightClass: EstimatedWeightClass,
        sourceEntryID: UUID? = nil
    ) {
        self.id = id
        self.itemName = itemName
        self.label = label
        self.carryType = carryType
        self.count = count
        self.estimatedWeightClass = estimatedWeightClass
        self.sourceEntryID = sourceEntryID
    }
}

enum CarryType: String, Codable, CaseIterable, Hashable, Sendable {
    case physicalBin
    case bundleGroup
    case looseCarry

    var displayName: String {
        switch self {
        case .physicalBin: return "Physical Bin"
        case .bundleGroup: return "Bundle Group"
        case .looseCarry: return "Loose Carry"
        }
    }
}

enum EstimatedWeightClass: String, Codable, CaseIterable, Hashable, Sendable {
    case light
    case medium
    case heavy

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }
}
