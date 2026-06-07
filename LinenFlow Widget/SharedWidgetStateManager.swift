import Foundation

enum SharedWidgetStateManager {
    static let appGroupID = "group.com.himmerflow.shared"
    static let legacyAppGroupID = "group.com.linenflow.shared"
    static let widgetStateKey = "himmerflow.widgetState"
    private static let legacyWidgetStateKeys = ["linenflow.widgetState", "com.linenflow.widgetState"]
    private static let migrationCompletedKey = "himmerflow.migratedFromLinenFlow"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> SharedWidgetState {
        if let data = defaults.data(forKey: widgetStateKey),
           let state = try? JSONDecoder().decode(SharedWidgetState.self, from: data) {
            return state
        }

        if let migrated = migrateLegacyWidgetState() {
            return migrated
        }

        return defaultState()
    }

    static func save(_ state: SharedWidgetState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: widgetStateKey)
        defaults.synchronize()
    }

    static func clear() {
        defaults.removeObject(forKey: widgetStateKey)
    }

    static func defaultState() -> SharedWidgetState {
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

    private static func migrateLegacyWidgetState() -> SharedWidgetState? {
        guard !UserDefaults.standard.bool(forKey: migrationCompletedKey) else { return nil }

        let candidateDefaults: [UserDefaults] = [
            defaults,
            UserDefaults(suiteName: legacyAppGroupID)
        ].compactMap { $0 }

        for store in candidateDefaults {
            for key in legacyWidgetStateKeys {
                guard let data = store.data(forKey: key),
                      let state = try? JSONDecoder().decode(SharedWidgetState.self, from: data) else { continue }
                save(state)
                store.removeObject(forKey: key)
                UserDefaults.standard.set(true, forKey: migrationCompletedKey)
                return state
            }
        }

        return nil
    }
}
