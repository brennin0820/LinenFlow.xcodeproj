import Foundation

enum TimeshareReserveStatus: String, Codable, Hashable, Sendable {
    case exact
    case lowReserve
    case idealMorningReserve
    case overReserve

    var displayName: String {
        switch self {
        case .exact:
            return "Exact"
        case .lowReserve:
            return "Low Reserve"
        case .idealMorningReserve:
            return "Morning Reserve"
        case .overReserve:
            return "Over Reserve"
        }
    }

    var detail: String {
        switch self {
        case .exact:
            return "Exact count. No extra LRA buffer."
        case .lowReserve:
            return "Low reserve. Ideal LRA buffer is 20-25 pcs."
        case .idealMorningReserve:
            return "Ideal LRA buffer range for timeshare morning calls."
        case .overReserve:
            return "Over reserve. Confirm the count before staging extras."
        }
    }
}

struct TimeshareReserveResult: Hashable, Sendable {
    let reservePieces: Int
    let status: TimeshareReserveStatus
}

enum TimeshareReserveAlgorithm {
    static let idealRange = 20...25

    static func evaluate(reservePieces: Int) -> TimeshareReserveResult {
        let safeReserve = max(0, reservePieces)
        return TimeshareReserveResult(
            reservePieces: safeReserve,
            status: status(for: safeReserve)
        )
    }

    static func status(for reservePieces: Int) -> TimeshareReserveStatus {
        let safeReserve = max(0, reservePieces)
        switch safeReserve {
        case 0:
            return .exact
        case 1..<idealRange.lowerBound:
            return .lowReserve
        case idealRange:
            return .idealMorningReserve
        default:
            return .overReserve
        }
    }
}
