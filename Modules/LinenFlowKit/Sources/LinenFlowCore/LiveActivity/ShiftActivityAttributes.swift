import Foundation

#if canImport(ActivityKit)
import ActivityKit

public struct ShiftActivityAttributes: ActivityAttributes {
    public let shiftName: String
    public let clockInTime: Date

    public struct ContentState: Codable, Hashable {
        public var currentPhase: ShiftTimelinePhase
        public var nextActionLabel: String
        public var nextActionTime: Date
        public var progressFraction: Double
        public var statusEmoji: String
    }
}
#endif
