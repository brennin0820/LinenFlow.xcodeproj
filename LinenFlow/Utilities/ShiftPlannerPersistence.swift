import Foundation
import OSLog

enum ShiftPlannerPersistence {
    static let appGroupID = SharedWidgetStateManager.appGroupID
    private static let locationStateKey = "himmerflow.shiftLocationState"
    private static let ackStateKey = "himmerflow.acknowledgementState"
    private static let activityIDKey = "himmerflow.shiftActivityID"
    private static let degradationBannerKey = "himmerflow.degradationBannerShown"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func loadLocationState() -> ShiftLocationState {
        guard let data = defaults.data(forKey: locationStateKey),
              let state = try? JSONDecoder().decode(ShiftLocationState.self, from: data) else {
            return ShiftLocationState()
        }
        return state
    }

    static func saveLocationState(_ state: ShiftLocationState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: locationStateKey)
        HimmerFlowLog.persistence.debug("Saved location state")
    }

    static func loadAcknowledgementState() -> AcknowledgementState {
        guard let data = defaults.data(forKey: ackStateKey),
              let state = try? JSONDecoder().decode(AcknowledgementState.self, from: data) else {
            return AcknowledgementState()
        }
        return state
    }

    static func saveAcknowledgementState(_ state: AcknowledgementState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: ackStateKey)
        HimmerFlowLog.persistence.debug("Saved acknowledgement state")
    }

    static func loadActivityID() -> String? {
        defaults.string(forKey: activityIDKey)
    }

    static func saveActivityID(_ id: String?) {
        if let id {
            defaults.set(id, forKey: activityIDKey)
        } else {
            defaults.removeObject(forKey: activityIDKey)
        }
    }

    static func resetSessionFlags() {
        defaults.removeObject(forKey: degradationBannerKey)
    }
}
