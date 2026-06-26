import Foundation
import LinenFlowCore

public enum BundleLibrary {
    /// Protected bundle constants. Do not change values without updating the build prompt's locked rules.
    public static let bundleSizes: [String: Int] = [
        "Bath Towel": 5,
        "Bath Mat": 10,
        "Hand Towel": 20,
        "Washcloth": 50,
        "Pillow Case": 50,
        "King Sheet": 5,
        "King Cover": 5,
        "Queen Sheet": 5,
        "Queen Cover": 5,
        "Double Sheet": 5,
        "Double Cover": 5,
        "Twin Sheet": 5,
        "Twin Cover": 5,
    ]

    /// Alias names that may appear on labels / cart sheets, mapped to their canonical item name.
    public static let aliases: [String: String] = [
        "Pillowcase": "Pillow Case",
        "Wash Cloth": "Washcloth",
        "Double Duvet": "Double Cover",
        "King Duvet": "King Cover",
        "King Duvet / King Cover": "King Cover",
        "Queen Duvet": "Queen Cover",
        "Queen Duvet / Queen Cover": "Queen Cover",
        "Twin Duvet": "Twin Cover",
        "Twin Duvet / Twin Cover": "Twin Cover",
        "TS": "Twin Sheet",
        "TC": "Twin Cover",
    ]

    /// All canonical item names, alphabetised.
    public static var canonicalNames: [String] {
        bundleSizes.keys.sorted()
    }

    /// Bundle size for a name. Accepts canonical names and known aliases (case-insensitive).
    public static func bundleSize(for name: String) -> Int? {
        bundleSizes[canonicalName(for: name)]
    }

    /// Resolve a name to its canonical form. Returns the input trimmed if no mapping is known.
    public static func canonicalName(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = bundleSizes.keys.first(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return direct
        }
        if let mapped = aliases.first(where: { $0.key.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return mapped.value
        }
        return trimmed
    }

    public static func isCanonical(_ name: String) -> Bool {
        bundleSizes.keys.contains(canonicalName(for: name))
    }
}
