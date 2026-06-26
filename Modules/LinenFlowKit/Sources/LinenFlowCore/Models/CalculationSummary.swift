import Foundation

public struct CalculationSummary: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var itemName: String
    public var receivedPieces: Int
    public var bundleSize: Int
    public var fullBundles: Int
    public var loosePieces: Int
    public var requiredPieces: Int
    public var requiredBundles: Int?
    public var maxAllowedBundles: Int
    public var deliverableBundles: Int
    public var shortageBundles: Int
    public var leftoverBundles: Int
    public var differencePieces: Int
    public var differenceBundles: Int
    public var status: CalculationStatus
    public var exactPerFloorPieces: Double
    public var basePerFloorPieces: Int
    public var remainderPieces: Int

    public init(
        id: UUID = UUID(),
        itemName: String,
        receivedPieces: Int,
        bundleSize: Int,
        fullBundles: Int,
        loosePieces: Int,
        requiredPieces: Int,
        requiredBundles: Int? = nil,
        maxAllowedBundles: Int = 0,
        deliverableBundles: Int = 0,
        shortageBundles: Int = 0,
        leftoverBundles: Int = 0,
        differencePieces: Int,
        differenceBundles: Int = 0,
        status: CalculationStatus,
        exactPerFloorPieces: Double,
        basePerFloorPieces: Int,
        remainderPieces: Int
    ) {
        self.id = id
        self.itemName = itemName
        self.receivedPieces = receivedPieces
        self.bundleSize = bundleSize
        self.fullBundles = fullBundles
        self.loosePieces = loosePieces
        self.requiredPieces = requiredPieces
        self.requiredBundles = requiredBundles
        self.maxAllowedBundles = maxAllowedBundles
        self.deliverableBundles = deliverableBundles
        self.shortageBundles = shortageBundles
        self.leftoverBundles = leftoverBundles
        self.differencePieces = differencePieces
        self.differenceBundles = differenceBundles
        self.status = status
        self.exactPerFloorPieces = exactPerFloorPieces
        self.basePerFloorPieces = basePerFloorPieces
        self.remainderPieces = remainderPieces
    }

    // MARK: - Backward-compatible decoder

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        itemName = try c.decode(String.self, forKey: .itemName)
        receivedPieces = try c.decode(Int.self, forKey: .receivedPieces)
        bundleSize = try c.decode(Int.self, forKey: .bundleSize)
        fullBundles = try c.decode(Int.self, forKey: .fullBundles)
        loosePieces = try c.decode(Int.self, forKey: .loosePieces)
        requiredPieces = try c.decode(Int.self, forKey: .requiredPieces)
        requiredBundles = try c.decodeIfPresent(Int.self, forKey: .requiredBundles)
        maxAllowedBundles = try c.decodeIfPresent(Int.self, forKey: .maxAllowedBundles) ?? 0
        deliverableBundles = try c.decodeIfPresent(Int.self, forKey: .deliverableBundles) ?? 0
        shortageBundles = try c.decodeIfPresent(Int.self, forKey: .shortageBundles) ?? 0
        leftoverBundles = try c.decodeIfPresent(Int.self, forKey: .leftoverBundles) ?? 0
        differencePieces = try c.decode(Int.self, forKey: .differencePieces)
        differenceBundles = try c.decodeIfPresent(Int.self, forKey: .differenceBundles) ?? 0
        status = try c.decode(CalculationStatus.self, forKey: .status)
        exactPerFloorPieces = try c.decode(Double.self, forKey: .exactPerFloorPieces)
        basePerFloorPieces = try c.decode(Int.self, forKey: .basePerFloorPieces)
        remainderPieces = try c.decode(Int.self, forKey: .remainderPieces)
    }
}
