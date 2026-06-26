import Foundation
import SwiftData

public enum TowerDeliveryMode: String, Codable, Sendable {
    case pieces
    case bundles
}

public enum TowerDisplayGroup: String, Codable, CaseIterable, Sendable {
    case pieceDistribution
    case bundleDelivery

    public var displayName: String {
        switch self {
        case .pieceDistribution: return "Piece Distribution"
        case .bundleDelivery: return "Bundle Delivery"
        }
    }

    public var subtitle: String {
        switch self {
        case .pieceDistribution: return "Count and distribute by pieces"
        case .bundleDelivery: return "Carry full bundles floor to floor"
        }
    }

    public var systemImage: String {
        switch self {
        case .pieceDistribution: return "number"
        case .bundleDelivery: return "shippingbox.fill"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .pieceDistribution: return 0
        case .bundleDelivery: return 1
        }
    }
}

@Model
public final class Tower {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var floorCount: Int
    public var isActive: Bool
    public var identityColorHex: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var deliveryModeRaw: String = TowerDeliveryMode.bundles.rawValue
    public var allowsDoubleItems: Bool = false

    // MARK: - Editable Floor Range
    // Source-of-truth inputs for the delivery floor sequence. A value of 0 for
    // startFloor or topFloor means "unset" so existing tower-policy fallbacks
    // continue to apply. When both are > 0 they drive floorCount and the
    // delivery floor sequence.
    public var startFloor: Int = 0
    public var topFloor: Int = 0
    public var skip13thFloor: Bool = false

    // MARK: - Barometer / Floor Sensing Calibration
    // These fields store per-tower calibration data gathered from public sources.
    // They do NOT activate any sensors; they prepare future barometer-based floor detection.
    public var estimatedFloorHeightMeters: Double = 3.1
    public var floorDetectionToleranceMeters: Double = 0.45
    public var floorMovementConfidenceThresholdMeters: Double = 1.2
    public var latitude: Double?
    public var longitude: Double?
    public var towerDataConfidence: String = "Unknown"
    public var towerDataNotes: String?

    public var deliveryMode: TowerDeliveryMode {
        get { TowerDeliveryMode(rawValue: deliveryModeRaw) ?? .bundles }
        set { deliveryModeRaw = newValue.rawValue }
    }

    public var displayGroup: TowerDisplayGroup {
        deliveryMode == .pieces ? .pieceDistribution : .bundleDelivery
    }

    public init(
        id: UUID = UUID(),
        name: String,
        floorCount: Int,
        isActive: Bool = true,
        identityColorHex: String? = nil,
        deliveryMode: TowerDeliveryMode = .bundles,
        allowsDoubleItems: Bool = false,
        startFloor: Int = 0,
        topFloor: Int = 0,
        skip13thFloor: Bool = false,
        estimatedFloorHeightMeters: Double = 3.1,
        floorDetectionToleranceMeters: Double = 0.45,
        floorMovementConfidenceThresholdMeters: Double = 1.2,
        latitude: Double? = nil,
        longitude: Double? = nil,
        towerDataConfidence: String = "Unknown",
        towerDataNotes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.floorCount = floorCount
        self.isActive = isActive
        self.identityColorHex = identityColorHex
        self.deliveryModeRaw = deliveryMode.rawValue
        self.allowsDoubleItems = allowsDoubleItems
        self.startFloor = startFloor
        self.topFloor = topFloor
        self.skip13thFloor = skip13thFloor
        self.estimatedFloorHeightMeters = estimatedFloorHeightMeters
        self.floorDetectionToleranceMeters = floorDetectionToleranceMeters
        self.floorMovementConfidenceThresholdMeters = floorMovementConfidenceThresholdMeters
        self.latitude = latitude
        self.longitude = longitude
        self.towerDataConfidence = towerDataConfidence
        self.towerDataNotes = towerDataNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// True when start/top floors have been configured by seed data or the user
    /// and form a valid range. When false, callers should fall back to legacy
    /// per-tower defaults.
    public var hasCustomFloorRange: Bool {
        startFloor >= 1 && topFloor >= startFloor
    }
}
