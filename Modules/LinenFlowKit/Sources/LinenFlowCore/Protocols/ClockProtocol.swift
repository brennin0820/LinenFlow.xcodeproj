import Foundation

public protocol ClockProtocol: Sendable {
    var now: Date { get }
}
