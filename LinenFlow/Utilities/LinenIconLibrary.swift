import Foundation
import SwiftUI

enum LinenIconLibrary {
    // MARK: - Items
    static func symbolName(forItem itemName: String) -> String {
        let name = itemName.lowercased()
        if name.contains("towel") || name.contains("mat") || name.contains("washcloth") {
            return "bathtub.fill"
        }
        if name.contains("sheet") || name.contains("cover") || name.contains("pillow") || name.contains("duvet") {
            return "bed.double.circle.fill"
        }
        return "sparkles"
    }

    /// Stable accent color for an item. Known items use a curated palette so
    /// they remain visually consistent across the app; unknown user-added items
    /// fall back to a deterministic hash of the name so the color stays the
    /// same between sessions.
    static func color(forItem itemName: String) -> Color {
        switch itemName {
        case "Bath Towel":   return .blue
        case "Bath Mat":     return .green
        case "Hand Towel":   return .orange
        case "Washcloth":    return .purple
        case "Pillow Case":  return .pink
        case "King Sheet", "King Cover":     return .teal
        case "Queen Sheet", "Queen Cover":   return .mint
        case "Double Sheet", "Double Cover": return .cyan
        case "Twin Sheet", "Twin Cover":     return Color(red: 0.45, green: 0.78, blue: 0.95)
        default:
            return fallbackColor(for: itemName)
        }
    }

    static func itemSortOrder(forItem itemName: String) -> Int {
        switch itemName {
        case "Bath Towel": return 10
        case "Bath Mat": return 20
        case "Hand Towel": return 30
        case "Washcloth": return 40
        case "Pillow Case": return 50
        case "King Sheet": return 60
        case "King Cover": return 61
        case "Queen Sheet": return 70
        case "Queen Cover": return 71
        case "Double Sheet": return 80
        case "Double Cover": return 81
        case "Twin Sheet": return 90
        case "Twin Cover": return 91
        default: return 1_000
        }
    }

    static func itemComesBefore(_ lhs: String, _ rhs: String) -> Bool {
        let lhsOrder = itemSortOrder(forItem: lhs)
        let rhsOrder = itemSortOrder(forItem: rhs)
        if lhsOrder == rhsOrder {
            return lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
        return lhsOrder < rhsOrder
    }

    private static let fallbackPalette: [Color] = [
        .blue, .cyan, .teal, .mint, .green, .yellow, .orange, .red, .pink, .purple, .indigo
    ]

    private static func fallbackColor(for itemName: String) -> Color {
        var hash: UInt32 = 5381
        for scalar in itemName.unicodeScalars {
            hash = (hash &* 33) &+ scalar.value
        }
        let index = Int(hash % UInt32(fallbackPalette.count))
        return fallbackPalette[index]
    }

    // MARK: - Towers
    static func symbolName(forTower towerName: String) -> String {
        let name = towerName.lowercased()
        if name.contains("lagoon") {
            return "drop.circle.fill"
        } else if name.contains("diamond") {
            return "diamond.fill"
        } else if name.contains("alii") {
            return "crown.fill"
        } else if name.contains("tapa") {
            return "leaf.fill"
        } else if name.contains("rainbow") {
            return "rainbow"
        }
        return "building.2.fill"
    }
    
    // MARK: - Delivery Modes
    static var pieceDistribution: String { "number" }
    static var bundleDelivery: String { "shippingbox.fill" }

    // MARK: - Status
    static func symbolName(forStatus status: CalculationStatus) -> String {
        switch status {
        case .shortage: return "exclamationmark.triangle.fill"
        case .overage: return "plus.circle.fill"
        case .exact: return "checkmark.seal.fill"
        }
    }
    
    // MARK: - Status Color
    static func color(forStatus status: CalculationStatus) -> Color {
        switch status {
        case .shortage: return .red
        case .overage: return .orange
        case .exact: return .green
        }
    }

    // MARK: - Workflow Steps
    static func symbolName(forWorkflowStep step: FlowStep) -> String {
        switch step {
        case .receiving: return "tray.and.arrow.down.fill"
        case .review: return "list.bullet.clipboard.fill"
        case .results: return "chart.bar.doc.horizontal.fill"
        case .floorPlan: return "figure.walk.motion"
        case .rebalance: return "arrow.triangle.2.circlepath"
        }
    }

    // MARK: - General UI Concepts
    enum General {
        static let settings = "gearshape.fill"
        static let logs = "clock.arrow.circlepath"
        static let home = "building.2"
        static let shift = "alarm.fill"
        static let clear = "xmark.circle.fill"
        static let save = "tray.and.arrow.down.fill"
        static let commandCenter = "command.circle.fill"
        static let checklistChecked = "checkmark.circle.fill"
        static let checklistUnchecked = "circle"
        static let warning = "exclamationmark.triangle.fill"
    }
}
