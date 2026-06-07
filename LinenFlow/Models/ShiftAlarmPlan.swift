import Foundation

struct ShiftAlarmPlan: Codable {
    var id: UUID = UUID()
    var isEnabled: Bool = true
    var getReadyEnabled: Bool = true
    var leaveSoonEnabled: Bool = true
    var checklistEnabled: Bool = true
    var walkToCarEnabled: Bool = true
    var startDrivingEnabled: Bool = true
    var shiftSoonEnabled: Bool = true
    var notificationSoundName: String? = nil
    var scheduledNotificationIdentifiers: [String] = []
}
