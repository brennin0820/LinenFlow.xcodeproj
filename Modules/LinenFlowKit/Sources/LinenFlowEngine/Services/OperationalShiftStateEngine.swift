import Foundation
import LinenFlowCore

public enum CountdownUrgencyLevel: String, Codable, Hashable {
    case calm
    case warm
    case urgent
    case critical
    case complete
    case inactive
}

public enum OperationalSemanticState: String, Codable, Hashable {
    case noActiveDelivery
    case ready
    case openingPass
    case activeRun
    case towelRun
    case midRun
    case finalFloors
    case finishing
    case paused
    case complete
    case overtime
    case demo

    public var displayName: String {
        switch self {
        case .noActiveDelivery: return "OPEN"
        case .ready: return "READY"
        case .openingPass: return "OPENING"
        case .activeRun: return "ACTIVE"
        case .towelRun: return "TOWELS"
        case .midRun: return "MID RUN"
        case .finalFloors: return "FINAL FLOORS"
        case .finishing: return "FINISHING"
        case .paused: return "PAUSED"
        case .complete: return "COMPLETE"
        case .overtime: return "OVERTIME"
        case .demo: return "DEMO"
        }
    }

    public var compactDisplayName: String {
        switch self {
        case .noActiveDelivery: return "OPEN"
        case .openingPass: return "OPEN"
        case .finalFloors: return "FINAL"
        default: return displayName
        }
    }
}

public struct OperationalShiftSnapshot: Hashable {
    public let towerName: String
    public let shortTowerName: String
    public let floorCount: Int
    public let completedFloors: Int
    public let remainingFloors: Int
    public let progressFraction: Double
    public let currentItemNames: [String]
    public let currentItemSummary: String
    public let nextCarryGroupTitle: String?
    public let targetTime: Date?
    public let countdownText: String
    public let compactCountdownText: String
    public let urgencyLevel: CountdownUrgencyLevel
    public let semanticState: OperationalSemanticState
    public let statusText: String
    public let isActiveSession: Bool
    public let isPaused: Bool
    public let isComplete: Bool
    public let isDemoDay: Bool
}

public enum OperationalShiftStateEngine {
    public static func snapshot(from state: SharedWidgetState) -> OperationalShiftSnapshot {
        snapshot(
            towerName: state.towerName,
            floorCount: state.floorCount,
            completedFloors: state.completedFloors,
            remainingFloors: state.remainingFloors,
            currentItemName: state.currentItemName,
            currentItemNames: state.currentItemNames,
            nextCarryGroupTitle: state.nextCarryGroupTitle,
            targetTime: state.targetTime,
            statusText: state.statusText,
            isActiveSession: state.isActiveSession,
            isPausedSession: state.isPausedSession,
            isDemoDay: state.isDemoDay
        )
    }

    public static func snapshot(
        towerName: String,
        floorCount: Int,
        completedFloors: Int,
        remainingFloors: Int,
        currentItemName: String?,
        currentItemNames: [String]?,
        nextCarryGroupTitle: String?,
        targetTime: Date?,
        statusText: String,
        isActiveSession: Bool,
        isPausedSession: Bool? = nil,
        isDemoDay: Bool = false
    ) -> OperationalShiftSnapshot {
        let safeFloorCount = max(0, floorCount)
        let safeCompleted = min(max(0, completedFloors), safeFloorCount)
        let safeRemaining = min(max(0, remainingFloors), safeFloorCount)
        let isComplete = safeFloorCount > 0 && safeRemaining == 0
        let isPaused = safeFloorCount > 0
            && !isComplete
            && ((isPausedSession == true) || (!isActiveSession && safeCompleted > 0 && safeRemaining > 0))
        let progress = safeFloorCount > 0 ? min(max(Double(safeCompleted) / Double(safeFloorCount), 0), 1) : 0
        let items = normalizedItems(currentItemName: currentItemName, currentItemNames: currentItemNames)
        let urgency = countdownUrgency(targetTime: targetTime, isComplete: isComplete, hasTower: safeFloorCount > 0)
        let semantic = semanticState(
            floorCount: safeFloorCount,
            completedFloors: safeCompleted,
            remainingFloors: safeRemaining,
            currentItemNames: items,
            targetTime: targetTime,
            urgencyLevel: urgency,
            isActiveSession: isActiveSession,
            isPaused: isPaused,
            isComplete: isComplete,
            isDemoDay: isDemoDay
        )

        return OperationalShiftSnapshot(
            towerName: towerName,
            shortTowerName: compactTowerName(towerName),
            floorCount: safeFloorCount,
            completedFloors: safeCompleted,
            remainingFloors: safeRemaining,
            progressFraction: progress,
            currentItemNames: items,
            currentItemSummary: items.isEmpty ? "No items queued" : items.joined(separator: " · "),
            nextCarryGroupTitle: nextCarryGroupTitle,
            targetTime: targetTime,
            countdownText: countdownText(targetTime: targetTime, fallback: statusText, isComplete: isComplete),
            compactCountdownText: countdownText(targetTime: targetTime, fallback: statusText, isComplete: isComplete, compact: true),
            urgencyLevel: urgency,
            semanticState: semantic,
            statusText: statusText,
            isActiveSession: isActiveSession,
            isPaused: isPaused,
            isComplete: isComplete,
            isDemoDay: isDemoDay
        )
    }

    public static func countdownUrgency(targetTime: Date?, isComplete: Bool, hasTower: Bool) -> CountdownUrgencyLevel {
        guard hasTower else { return .inactive }
        if isComplete { return .complete }
        guard let targetTime else { return .calm }
        let seconds = targetTime.timeIntervalSinceNow
        if seconds < 0 { return .critical }
        if seconds <= 30 * 60 { return .urgent }
        if seconds <= 120 * 60 { return .warm }
        return .calm
    }

    public static func compactTowerName(_ towerName: String) -> String {
        let trimmed = towerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "HF" }

        let words = trimmed.split(separator: " ")
        if words.count > 1 {
            return words.compactMap(\.first).prefix(2).map(String.init).joined().uppercased()
        }
        return String(trimmed.prefix(3)).uppercased()
    }

    private static func normalizedItems(currentItemName: String?, currentItemNames: [String]?) -> [String] {
        let source = currentItemNames ?? [currentItemName].compactMap { $0 }
        var seen: Set<String> = []
        let normalized = source
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
        return Array(normalized.prefix(3))
    }

    private static func semanticState(
        floorCount: Int,
        completedFloors: Int,
        remainingFloors: Int,
        currentItemNames: [String],
        targetTime: Date?,
        urgencyLevel: CountdownUrgencyLevel,
        isActiveSession: Bool,
        isPaused: Bool,
        isComplete: Bool,
        isDemoDay: Bool
    ) -> OperationalSemanticState {
        if floorCount == 0 { return .noActiveDelivery }
        if isDemoDay { return .demo }
        if isPaused { return .paused }
        if isComplete { return .complete }
        if urgencyLevel == .critical { return .overtime }
        guard isActiveSession else { return .ready }
        if remainingFloors <= 3 { return .finalFloors }
        if currentItemNames.contains(where: { $0.localizedCaseInsensitiveContains("towel") }) { return .towelRun }
        if completedFloors <= 2 { return .openingPass }
        if urgencyLevel == .urgent { return .finishing }
        if floorCount > 0, Double(completedFloors) / Double(floorCount) >= 0.45 { return .midRun }
        return .activeRun
    }

    private static func countdownText(
        targetTime: Date?,
        fallback: String,
        isComplete: Bool,
        compact: Bool = false
    ) -> String {
        if isComplete { return compact ? "Done" : "Shift complete" }
        guard let targetTime else { return fallback }
        let raw = targetTime.timeIntervalSinceNow
        if raw < 0 {
            let over = Int(-raw / 60) + 1
            return compact ? "+\(over)m" : "Overtime +\(over)m"
        }
        let seconds = Int(raw)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return compact ? "\(hours)h \(minutes)m" : "\(hours)h \(minutes)m left" }
        if minutes > 0 { return compact ? "\(minutes)m" : "\(minutes)m left" }
        return "Due now"
    }
}
