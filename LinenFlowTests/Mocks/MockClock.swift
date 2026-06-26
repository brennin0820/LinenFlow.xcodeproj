import Foundation
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class MockClock: ClockProtocol, @unchecked Sendable {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}
