import Foundation
import LinenFlowCore

/// Filters persisted daily logs for the Logs tab.
public enum LogFilter: Hashable, Identifiable, CaseIterable {
    case all
    case tower(String)
    case shortages

    public static var allCases: [LogFilter] {
        [.all] + DefaultData.towers.map { .tower($0.name) } + [.shortages]
    }

    public var id: String { label }

    public var label: String {
        switch self {
        case .all: return "All"
        case .tower(let name): return name
        case .shortages: return "Shortages"
        }
    }
}

public enum LogFilterBuilder {
    /// Returns logs matching the selected filter, preserving input order.
    public static func filter(_ logs: [DailyLog], by filter: LogFilter) -> [DailyLog] {
        switch filter {
        case .all:
            return logs
        case .tower(let name):
            return logs.filter { $0.towerName == name }
        case .shortages:
            return logs.filter { log in
                log.summarySnapshot.contains { $0.status == .shortage }
            }
        }
    }

    /// Counts logs per filter — useful for Insights and empty-state messaging.
    public static func counts(for logs: [DailyLog]) -> [LogFilter: Int] {
        Dictionary(uniqueKeysWithValues: LogFilter.allCases.map { option in
            (option, filter(logs, by: option).count)
        })
    }
}
