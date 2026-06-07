import Foundation
import SwiftData
import OSLog

private let saveLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.himmerflow.app",
    category: "logs"
)

enum SaveLogError: Error, LocalizedError, Equatable {
    case noTower
    case noEntries
    case invalidCalculations
    case persistFailure(String)

    var errorDescription: String? {
        switch self {
        case .noTower:            return "Select a tower before saving."
        case .noEntries:          return "Enter at least one item before saving."
        case .invalidCalculations: return "Calculations are not ready — recalculate before saving."
        case .persistFailure(let msg): return "Save failed: \(msg)"
        }
    }
}

enum DailyLogSaveService {
    @MainActor
    static func save(viewModel: FlowViewModel, context: ModelContext) -> Result<DailyLog, SaveLogError> {
        guard viewModel.selectedTower != nil else { return .failure(.noTower) }
        guard !viewModel.receivingEntries.isEmpty else { return .failure(.noEntries) }
        guard !viewModel.calculationSummaries.isEmpty else { return .failure(.invalidCalculations) }

        guard let log = viewModel.buildDailyLog() else {
            return .failure(.invalidCalculations)
        }

        // Same-day deduplication: if a log for the same tower already exists
        // today, update it in place instead of creating a duplicate.
        let towerName = log.towerName
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date.now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay.addingTimeInterval(86_400)

        let predicate = #Predicate<DailyLog> { existing in
            existing.towerName == towerName
            && existing.date >= startOfDay
            && existing.date < endOfDay
        }
        let descriptor = FetchDescriptor<DailyLog>(predicate: predicate)
        let existingLog = (try? context.fetch(descriptor))?.first

        let savedLog: DailyLog
        if let existingLog {
            existingLog.update(
                floorCount: log.floorCount,
                entriesSnapshot: log.entriesSnapshot,
                summarySnapshot: log.summarySnapshot,
                distributionSnapshot: log.distributionSnapshot,
                notes: log.notes
            )
            savedLog = existingLog
            saveLogger.info("Daily log updated (same-day): \(savedLog.towerName, privacy: .public) \(savedLog.date.formatted(date: .abbreviated, time: .omitted), privacy: .public)")
        } else {
            context.insert(log)
            savedLog = log
            saveLogger.info("Daily log saved: \(savedLog.towerName, privacy: .public) \(savedLog.date.formatted(date: .abbreviated, time: .omitted), privacy: .public)")
        }

        do {
            try context.save()
            return .success(savedLog)
        } catch {
            saveLogger.error("Daily log save failed: \(error, privacy: .public)")
            return .failure(.persistFailure(error.localizedDescription))
        }
    }
}
