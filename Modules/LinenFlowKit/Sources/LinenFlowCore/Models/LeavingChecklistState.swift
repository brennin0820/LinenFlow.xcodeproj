import Foundation

public struct LeavingChecklistState: Codable {
    public var id: UUID = UUID()
    public var items: [LeavingChecklistItem] = []
    public var remindBeforeWalkToCarMinutes: Int = 5
    public var isChecklistReminderEnabled: Bool = true
    public var isWiFiDisconnectReminderEnabled: Bool = false
    public var homeWiFiName: String? = nil
    public var todayCheckedItemIDs: [UUID] = []
    public var lastResetDate: Date? = nil
}
