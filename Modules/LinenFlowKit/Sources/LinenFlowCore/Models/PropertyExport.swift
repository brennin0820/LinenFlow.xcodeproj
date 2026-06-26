import Foundation

public struct PropertyExport: Codable {
    public var version: Int = 1
    public var towers: [TowerExport]
    public var linenItems: [LinenItemExport]
}

public struct TowerExport: Codable {
    public var name: String
    public var floorCount: Int
    public var isActive: Bool
    public var identityColorHex: String?
    public var deliveryModeRaw: String
    public var allowsDoubleItems: Bool
    public var startFloor: Int
    public var topFloor: Int
    public var skip13thFloor: Bool
    public var estimatedFloorHeightMeters: Double
    public var floorDetectionToleranceMeters: Double
    public var floorMovementConfidenceThresholdMeters: Double
    public var latitude: Double?
    public var longitude: Double?
    public var towerDataConfidence: String
    public var towerDataNotes: String?
}

public struct LinenItemExport: Codable {
    public var name: String
    public var parCount: Int
    public var countMethodRaw: String
    public var bundleSize: Int
    public var piecesPerBin: Int?
    public var isActive: Bool
    public var availabilityScopeRaw: String
    public var allowedTowerNames: [String]
}
