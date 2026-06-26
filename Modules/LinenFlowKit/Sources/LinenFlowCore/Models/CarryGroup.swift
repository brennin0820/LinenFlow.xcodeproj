import Foundation

public struct CarryGroup: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var itemName: String
    public var label: String
    public var carryType: CarryType
    public var count: Int
    public var estimatedWeightClass: EstimatedWeightClass
    public var sourceEntryID: UUID?

    public init(
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

public enum CarryType: String, Codable, CaseIterable, Hashable, Sendable {
    case physicalBin
    case bundleGroup
    case looseCarry

    public var displayName: String {
        switch self {
        case .physicalBin: return "Physical Bin"
        case .bundleGroup: return "Bundle Group"
        case .looseCarry: return "Loose Carry"
        }
    }
}

public enum EstimatedWeightClass: String, Codable, CaseIterable, Hashable, Sendable {
    case light
    case medium
    case heavy

    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }
}
