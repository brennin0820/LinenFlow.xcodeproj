import Foundation

/// Filters persisted daily logs for the Logs tab.
enum LogFilter: Hashable, Identifiable, CaseIterable {
    case all
    case tower(String)
    case shortages

    static var allCases: [LogFilter] {
        [.all] + DefaultData.towers.map { .tower($0.name) } + [.shortages]
    }

    var id: String { label }

    var label: String {
        switch self {
        case .all: return "All"
        case .tower(let name): return name
        case .shortages: return "Shortages"
        }
    }
}

enum LogFilterBuilder {
    /// Returns logs matching the selected filter, preserving input order.
    static func filter(_ logs: [DailyLog], by filter: LogFilter) -> [DailyLog] {
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
    static func counts(for logs: [DailyLog]) -> [LogFilter: Int] {
        Dictionary(uniqueKeysWithValues: LogFilter.allCases.map { option in
            (option, filter(logs, by: option).count)
        })
    }
}
