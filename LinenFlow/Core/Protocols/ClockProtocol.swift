import Foundation

protocol ClockProtocol: Sendable {
    var now: Date { get }
}
