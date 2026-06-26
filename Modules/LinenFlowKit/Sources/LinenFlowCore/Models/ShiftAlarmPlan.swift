import Foundation

public struct ShiftAlarmPlan: Codable {
    public var id: UUID = UUID()
    public var isEnabled: Bool = true
    public var getReadyEnabled: Bool = true
    public var leaveSoonEnabled: Bool = true
    public var checklistEnabled: Bool = true
    public var walkToCarEnabled: Bool = true
    public var startDrivingEnabled: Bool = true
    public var shiftSoonEnabled: Bool = true
    public var notificationSoundName: String? = nil
    public var scheduledNotificationIdentifiers: [String] = []
}
