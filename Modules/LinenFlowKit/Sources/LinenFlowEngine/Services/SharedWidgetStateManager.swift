import Foundation
import OSLog
import LinenFlowCore

private let widgetStateLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.himmerflow.app",
    category: "widget"
)

/// Shared shift Live Activity snapshot for the app group (widget extension + background rehydration).
public struct ShiftLiveActivitySharedState: Codable, Equatable {
    public var shiftName: String
    public var clockInTime: Date?
    public var currentPhaseRawValue: Int
    public var nextActionLabel: String
    public var nextActionTime: Date?
    public var progressFraction: Double
    public var statusEmoji: String
    public var lastUpdated: Date

    public static func from(content: ShiftActivityContent) -> ShiftLiveActivitySharedState {
        ShiftLiveActivitySharedState(
            shiftName: content.shiftName,
            clockInTime: content.clockInTime,
            currentPhaseRawValue: content.currentPhase.rawValue,
            nextActionLabel: content.nextActionLabel,
            nextActionTime: content.nextActionTime,
            progressFraction: content.progressFraction,
            statusEmoji: content.statusEmoji,
            lastUpdated: .now
        )
    }
}

public enum SharedWidgetStateManager {
    public static let appGroupID = "group.com.himmerflow.shared"
    public static let legacyAppGroupID = "group.com.linenflow.shared"
    public static let widgetStateKey = "himmerflow.widgetState"
    public static let shiftLiveActivityStateKey = "himmerflow.shiftLiveActivityState"
    private static let legacyWidgetStateKeys = ["linenflow.widgetState", "com.linenflow.widgetState"]
    private static let migrationCompletedKey = "himmerflow.migratedFromLinenFlow"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    public static func load() -> SharedWidgetState {
        if let data = defaults.data(forKey: widgetStateKey) {
            return decodeOrDefault(data)
        }

        if let migrated = migrateLegacyWidgetState() {
            return migrated
        }

        return defaultState()
    }

    public static func save(_ state: SharedWidgetState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: widgetStateKey)
        defaults.synchronize()
    }

    public static func clear() {
        defaults.removeObject(forKey: widgetStateKey)
    }

    public static func loadShiftLiveActivityState() -> ShiftLiveActivitySharedState? {
        guard let data = defaults.data(forKey: shiftLiveActivityStateKey) else { return nil }
        return try? JSONDecoder().decode(ShiftLiveActivitySharedState.self, from: data)
    }

    public static func saveShiftLiveActivityState(_ state: ShiftLiveActivitySharedState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: shiftLiveActivityStateKey)
        defaults.synchronize()
        widgetStateLogger.debug("Saved shift live activity shared state")
    }

    public static func clearShiftLiveActivityState() {
        defaults.removeObject(forKey: shiftLiveActivityStateKey)
    }

    public static func defaultState() -> SharedWidgetState {
        SharedWidgetState(
            towerName: "No Active Tower",
            towerColorHex: nil,
            floorCount: 0,
            completedFloors: 0,
            remainingFloors: 0,
            targetTime: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            currentItemName: nil,
            nextCarryGroupTitle: nil,
            statusText: "Open HimmerFlow to start",
            lastUpdated: .now,
            isActiveSession: false,
            isDemoDay: false
        )
    }

    private static func decodeOrDefault(_ data: Data) -> SharedWidgetState {
        do {
            return try JSONDecoder().decode(SharedWidgetState.self, from: data)
        } catch {
            widgetStateLogger.error("Widget state decode failed — returning default. Error: \(error, privacy: .public)")
            return defaultState()
        }
    }

    private static func migrateLegacyWidgetState() -> SharedWidgetState? {
        guard !UserDefaults.standard.bool(forKey: migrationCompletedKey) else { return nil }

        let candidateDefaults: [UserDefaults] = [
            defaults,
            UserDefaults(suiteName: legacyAppGroupID)
        ].compactMap { $0 }

        for store in candidateDefaults {
            for key in legacyWidgetStateKeys {
                guard let data = store.data(forKey: key) else { continue }
                let state = decodeOrDefault(data)
                save(state)
                store.removeObject(forKey: key)
                UserDefaults.standard.set(true, forKey: migrationCompletedKey)
                widgetStateLogger.info("Migrated widget state from legacy key \(key, privacy: .public)")
                return state
            }
        }

        return nil
    }
}
