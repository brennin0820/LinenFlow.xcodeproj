import Foundation

enum CountMethod: String, Codable, CaseIterable, Hashable, Sendable {
    case fixedBin
    case manualPieces
    case cartLabelPieces

    var displayName: String {
        switch self {
        case .fixedBin: return "Fixed Bin"
        case .manualPieces: return "Manual Pieces"
        case .cartLabelPieces: return "Cart / Label Pieces"
        }
    }
}
