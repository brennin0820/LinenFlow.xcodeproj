import Foundation
import LinenFlowCore

public struct SystemClock: ClockProtocol {
    public var now: Date { Date.now }
}

public struct FixedClock: ClockProtocol {
    public let fixedDate: Date
    public var now: Date { fixedDate }
}
