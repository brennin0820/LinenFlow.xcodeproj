import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public enum WorkScheduleTowerColor {
    /// Resolves tower accent colors from `DefaultData.towers` seed hex values,
    /// with aliases for schedule naming variants (e.g. "Grand Waikikian" → GW).
    public static func color(for name: String) -> Color {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, normalized != "unassigned", normalized != "other" else {
            return .blue
        }

        let canonical = canonicalName(for: normalized, original: name.trimmingCharacters(in: .whitespacesAndNewlines))
        if let hex = hexByCanonicalName[canonical], let color = Color(hex: hex) {
            return color
        }
        return .blue
    }

    private static let hexByCanonicalName: [String: String] = Dictionary(
        uniqueKeysWithValues: DefaultData.towers.compactMap { tower -> (String, String)? in
            guard let hex = tower.identityColorHex else { return nil }
            return (tower.name, hex)
        }
    )

    private static func canonicalName(for normalized: String, original: String) -> String {
        switch normalized {
        case "grand waikikian", "gw":
            return "GW"
        case "grand islander", "gi":
            return "GI"
        case "ali'i", "alii":
            return "Alii"
        case "lagoon":
            return "Lagoon"
        case "tapa":
            return "Tapa"
        case "rainbow":
            return "Rainbow"
        case "diamond":
            return "Diamond"
        case "kalia":
            return "Kalia"
        default:
            return DefaultData.towers.first { $0.name.lowercased() == normalized }?.name
                ?? original
        }
    }
}
