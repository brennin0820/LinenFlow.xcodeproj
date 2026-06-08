import Foundation

struct SystemClock: ClockProtocol {
    var now: Date { Date.now }
}

struct FixedClock: ClockProtocol {
    let fixedDate: Date
    var now: Date { fixedDate }
}
