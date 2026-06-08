import Foundation
@testable import HimmerFlow

final class MockClock: ClockProtocol, @unchecked Sendable {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}
