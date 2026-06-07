import Foundation

struct PropertyExport: Codable {
    var version: Int = 1
    var towers: [TowerExport]
    var linenItems: [LinenItemExport]
}

struct TowerExport: Codable {
    var name: String
    var floorCount: Int
    var isActive: Bool
    var identityColorHex: String?
    var deliveryModeRaw: String
    var allowsDoubleItems: Bool
    var startFloor: Int
    var topFloor: Int
    var skip13thFloor: Bool
    var estimatedFloorHeightMeters: Double
    var floorDetectionToleranceMeters: Double
    var floorMovementConfidenceThresholdMeters: Double
    var latitude: Double?
    var longitude: Double?
    var towerDataConfidence: String
    var towerDataNotes: String?
}

struct LinenItemExport: Codable {
    var name: String
    var parCount: Int
    var countMethodRaw: String
    var bundleSize: Int
    var piecesPerBin: Int?
    var isActive: Bool
    var availabilityScopeRaw: String
    var allowedTowerNames: [String]
}
