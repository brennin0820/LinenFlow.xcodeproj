import Foundation

struct LeavingChecklistState: Codable {
    var id: UUID = UUID()
    var items: [LeavingChecklistItem] = []
    var remindBeforeWalkToCarMinutes: Int = 5
    var isChecklistReminderEnabled: Bool = true
    var isWiFiDisconnectReminderEnabled: Bool = false
    var homeWiFiName: String? = nil
    var todayCheckedItemIDs: [UUID] = []
    var lastResetDate: Date? = nil
}
