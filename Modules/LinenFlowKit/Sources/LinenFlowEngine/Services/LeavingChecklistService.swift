import Foundation
import LinenFlowCore

public enum LeavingChecklistService {
    public static func buildDefaultItems() -> [LeavingChecklistItem] {
        [
            LeavingChecklistItem(title: "AirPods", isEnabled: true, sortOrder: 0),
            LeavingChecklistItem(title: "Charger", isEnabled: true, sortOrder: 1),
            LeavingChecklistItem(title: "Vape", isEnabled: true, sortOrder: 2)
        ]
    }

    public static func activeItems(from items: [LeavingChecklistItem]) -> [LeavingChecklistItem] {
        items.filter(\.isEnabled).sorted { $0.sortOrder < $1.sortOrder }
    }

    public static func buildNotificationBody(from items: [LeavingChecklistItem]) -> String {
        let active = activeItems(from: items)
        guard !active.isEmpty else {
            return "Check your leaving checklist before heading out."
        }
        if active.count > 4 {
            return "Check your leaving checklist before heading out."
        }
        let names = active.map { $0.title.lowercased() }
        if names.count == 1 {
            return "Check \(names[0]) before leaving."
        }
        let last = names[names.count - 1]
        let rest = names.dropLast().joined(separator: ", ")
        return "Check \(rest), and \(last) before leaving."
    }

    public static func calculateChecklistReminderTime(walkToCarTime: Date, remindBeforeMinutes: Int) -> Date {
        walkToCarTime.addingTimeInterval(-Double(remindBeforeMinutes) * 60)
    }

    public static func shouldResetCheckedItems(lastResetDate: Date?, referenceDate: Date = .now) -> Bool {
        guard let lastReset = lastResetDate else { return true }
        return !Calendar.current.isDate(lastReset, inSameDayAs: referenceDate)
    }
}
