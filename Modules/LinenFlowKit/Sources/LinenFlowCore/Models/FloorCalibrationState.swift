import Foundation

public struct FloorCalibrationState: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var towerName: String
    public var referenceFloor: Int
    public var floorHeightMeters: Double
    public var verticalDeltaMeters: Double
    public var floorsMeasured: Int
    public var calibratedAt: Date?
    public var isCalibrated: Bool
    public var note: String?

    public init(
        id: UUID = UUID(),
        towerName: String = "",
        referenceFloor: Int = 0,
        floorHeightMeters: Double = 3.2,
        verticalDeltaMeters: Double = 0,
        floorsMeasured: Int = 0,
        calibratedAt: Date? = nil,
        isCalibrated: Bool = false,
        note: String? = "Real-device calibration not set. Manual tracking remains active."
    ) {
        self.id = id
        self.towerName = towerName
        self.referenceFloor = referenceFloor
        self.floorHeightMeters = floorHeightMeters
        self.verticalDeltaMeters = verticalDeltaMeters
        self.floorsMeasured = max(0, floorsMeasured)
        self.calibratedAt = calibratedAt
        self.isCalibrated = isCalibrated
        self.note = note
    }
}
