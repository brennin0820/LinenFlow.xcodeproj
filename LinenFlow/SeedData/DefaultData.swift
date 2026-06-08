import Foundation

enum DefaultData {
    struct TowerDefault {
        let name: String
        let floorCount: Int
        let identityColorHex: String?
        let deliveryMode: TowerDeliveryMode
        let allowsDoubleItems: Bool
        /// Default start floor for the delivery range. Use 0 to leave unset so the
        /// legacy per-tower sequence applies (e.g., GW has multi-gap floors that a
        /// simple start/top/skip13 range can't capture).
        let startFloor: Int
        let topFloor: Int
        let skip13thFloor: Bool
    }

    // MARK: - Tower Calibration Data
    // Gathered from public architectural sources for Hilton Hawaiian Village towers.
    // Used to seed per-tower floor height for future barometer-based floor sensing.
    // Confidence levels reflect source quality; low = estimated only.
    struct TowerCalibration {
        let estimatedFloorHeightMeters: Double
        let floorDetectionToleranceMeters: Double
        let floorMovementConfidenceThresholdMeters: Double
        let latitude: Double?
        let longitude: Double?
        let confidence: String
        let notes: String
    }

    /// Keyed by the exact tower name used in DefaultData.towers.
    static let towerCalibrations: [String: TowerCalibration] = [
        "Tapa": .init(
            estimatedFloorHeightMeters: 3.17,
            floorDetectionToleranceMeters: 0.45,
            floorMovementConfidenceThresholdMeters: 1.2,
            latitude: 21.28158,
            longitude: -157.83809,
            confidence: "High",
            notes: "Public source: 114m / 36 floors ≈ 3.17m per floor."
        ),
        "GW": .init(
            estimatedFloorHeightMeters: 2.95,
            floorDetectionToleranceMeters: 0.45,
            floorMovementConfidenceThresholdMeters: 1.2,
            latitude: 21.2843,
            longitude: -157.8370,
            confidence: "High",
            notes: "Public source: 112m / 38 floors ≈ 2.95m per floor. Delivery floors may differ from architectural floors."
        ),
        "Kalia": .init(
            estimatedFloorHeightMeters: 3.20,
            floorDetectionToleranceMeters: 0.45,
            floorMovementConfidenceThresholdMeters: 1.2,
            latitude: 21.28472,
            longitude: -157.83862,
            confidence: "Medium",
            notes: "Public source implied ~3.96m/floor, likely including podium/mechanical structure. Safer sensing default is 3.20m."
        ),
        "Rainbow": .init(
            estimatedFloorHeightMeters: 2.87,
            floorDetectionToleranceMeters: 0.45,
            floorMovementConfidenceThresholdMeters: 1.2,
            latitude: 21.2821542,
            longitude: -157.8382747,
            confidence: "High",
            notes: "Public source: 89m / 31 floors ≈ 2.87m per floor."
        ),
        "Lagoon": .init(
            estimatedFloorHeightMeters: 3.17,
            floorDetectionToleranceMeters: 0.45,
            floorMovementConfidenceThresholdMeters: 1.2,
            latitude: 21.2833196,
            longitude: -157.8382704,
            confidence: "High",
            notes: "Public source: 73m / 23 floors ≈ 3.17m per floor."
        ),
        "GI": .init(
            estimatedFloorHeightMeters: 3.20,
            floorDetectionToleranceMeters: 0.45,
            floorMovementConfidenceThresholdMeters: 1.2,
            latitude: 21.28248378,
            longitude: -157.83551005,
            confidence: "Medium",
            notes: "Public 38-story data found. Exact architectural height not verified. 3.20m used as initial calibration."
        ),
        "Alii": .init(
            estimatedFloorHeightMeters: 3.10,
            floorDetectionToleranceMeters: 0.45,
            floorMovementConfidenceThresholdMeters: 1.2,
            latitude: 21.28274,
            longitude: -157.83638,
            confidence: "Low",
            notes: "Coordinates mapped from Hilton Hawaiian Village satellite reference."
        ),
        "Diamond": .init(
            estimatedFloorHeightMeters: 3.10,
            floorDetectionToleranceMeters: 0.45,
            floorMovementConfidenceThresholdMeters: 1.2,
            latitude: 21.28108,
            longitude: -157.83558,
            confidence: "Low",
            notes: "Exact public architectural height not verified. App currently uses operational 15 delivery floors."
        ),
    ]

    struct LinenItemDefault {
        let name: String
        let parCount: Int
        let bundleSize: Int
        let countMethod: CountMethod
        let piecesPerBin: Int?
        let allowedTowerNames: [String]
        let availabilityScope: ItemAvailabilityScope
    }

    static let towers: [TowerDefault] = [
        // Defaults below reproduce the legacy per-tower delivery counts.
        // GW has multi-gap floors (5–12, 14–32, 35–39) that a single
        // start/top/skip13 range can't express, so it stays unset (0/0/false)
        // and falls through to the per-tower sequence in
        // DeliveryFloorSequenceService until a user edits it.
        .init(name: "Lagoon",  floorCount: 21, identityColorHex: "#00A6C8", deliveryMode: .pieces,  allowsDoubleItems: false, startFloor: 3,  topFloor: 24, skip13thFloor: true),
        .init(name: "GI",      floorCount: 32, identityColorHex: "#C89B3C", deliveryMode: .pieces,  allowsDoubleItems: false, startFloor: 4,  topFloor: 36, skip13thFloor: true),
        .init(name: "GW",      floorCount: 32, identityColorHex: "#2F6F8F", deliveryMode: .pieces,  allowsDoubleItems: false, startFloor: 0,  topFloor: 0,  skip13thFloor: false),
        .init(name: "Diamond", floorCount: 15, identityColorHex: "#7C878E", deliveryMode: .bundles, allowsDoubleItems: true,  startFloor: 1,  topFloor: 15, skip13thFloor: false),
        .init(name: "Alii",    floorCount: 14, identityColorHex: "#7B3F98", deliveryMode: .bundles, allowsDoubleItems: true,  startFloor: 1,  topFloor: 14, skip13thFloor: false),
        .init(name: "Tapa",    floorCount: 33, identityColorHex: "#B66A35", deliveryMode: .bundles, allowsDoubleItems: false, startFloor: 3,  topFloor: 35, skip13thFloor: false),
        .init(name: "Rainbow", floorCount: 31, identityColorHex: "#F05A7E", deliveryMode: .bundles, allowsDoubleItems: false, startFloor: 2,  topFloor: 31, skip13thFloor: true),
        .init(name: "Kalia",   floorCount: 26, identityColorHex: "#7BAE7F", deliveryMode: .bundles, allowsDoubleItems: false, startFloor: 5,  topFloor: 31, skip13thFloor: true),
    ]

    static let linenItems: [LinenItemDefault] = [
        .init(name: "Bath Towel",   parCount: 14, bundleSize: 5,  countMethod: .fixedBin,      piecesPerBin: 245, allowedTowerNames: [],                                                     availabilityScope: .allTowers),
        .init(name: "Bath Mat",     parCount: 3,  bundleSize: 10, countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: [],                                                     availabilityScope: .allTowers),
        .init(name: "Hand Towel",   parCount: 4,  bundleSize: 20, countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: [],                                                     availabilityScope: .allTowers),
        .init(name: "Washcloth",    parCount: 2,  bundleSize: 50, countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: [],                                                     availabilityScope: .allTowers),
        .init(name: "Pillow Case",  parCount: 3,  bundleSize: 50, countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: [],                                                     availabilityScope: .allTowers),
        .init(name: "King Sheet",   parCount: 3,  bundleSize: 5,  countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: ["Alii", "Diamond", "Tapa", "Rainbow"],                availabilityScope: .selectedTowers),
        .init(name: "King Cover",   parCount: 3,  bundleSize: 5,  countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: ["Alii", "Diamond", "Tapa", "Rainbow"],                availabilityScope: .selectedTowers),
        .init(name: "Queen Sheet",  parCount: 4,  bundleSize: 5,  countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: ["Tapa", "Rainbow"],                                   availabilityScope: .selectedTowers),
        .init(name: "Queen Cover",  parCount: 4,  bundleSize: 5,  countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: ["Tapa", "Rainbow"],                                   availabilityScope: .selectedTowers),
        .init(name: "Double Sheet", parCount: 4,  bundleSize: 5,  countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: ["Alii", "Diamond"],                                   availabilityScope: .selectedTowers),
        .init(name: "Double Cover", parCount: 4,  bundleSize: 5,  countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: ["Alii", "Diamond"],                                   availabilityScope: .selectedTowers),
        .init(name: "Twin Sheet",   parCount: 4,  bundleSize: 5,  countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: [],                                                     availabilityScope: .allTowers),
        .init(name: "Twin Cover",   parCount: 4,  bundleSize: 5,  countMethod: .manualPieces,  piecesPerBin: nil, allowedTowerNames: [],                                                     availabilityScope: .allTowers),
    ]
}
