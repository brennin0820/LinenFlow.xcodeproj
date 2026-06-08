import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct ShiftActivityAttributes: ActivityAttributes {
    let shiftName: String
    let clockInTime: Date

    struct ContentState: Codable, Hashable {
        var currentPhase: ShiftTimelinePhase
        var nextActionLabel: String
        var nextActionTime: Date
        var progressFraction: Double
        var statusEmoji: String
    }
}
#endif
