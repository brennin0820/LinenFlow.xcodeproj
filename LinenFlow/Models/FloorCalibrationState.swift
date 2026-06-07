import Foundation

struct FloorCalibrationState: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var towerName: String
    var referenceFloor: Int
    var floorHeightMeters: Double
    var verticalDeltaMeters: Double
    var floorsMeasured: Int
    var calibratedAt: Date?
    var isCalibrated: Bool
    var note: String?

    init(
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
