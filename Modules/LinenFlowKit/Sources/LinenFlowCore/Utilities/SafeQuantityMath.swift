import Foundation

/// Overflow-safe integer arithmetic for nonnegative inventory quantities.
/// Saturation prevents an unexpectedly large input from crashing the app.
public enum SafeQuantityMath {
    /// Returns zero for negative inputs and Int.max if multiplication overflows.
    public static func nonNegativeProduct(_ lhs: Int, _ rhs: Int) -> Int {
        let (product, overflow) = max(0, lhs).multipliedReportingOverflow(by: max(0, rhs))
        return overflow ? Int.max : product
    }

    /// Integer-only ceiling division. Avoids Double rounding at Int.max.
    public static func ceilNonNegativeDivision(_ numerator: Int, by divisor: Int) -> Int {
        guard divisor > 0 else { return 0 }
        let safeNumerator = max(0, numerator)
        let quotient = safeNumerator / divisor
        return quotient + (safeNumerator % divisor == 0 ? 0 : 1)
    }

    /// Whole bundles over par (truncate toward zero) or short (round away
    /// from zero). Does not use abs(), which traps on Int.min.
    public static func signedBundleDifference(differencePieces: Int, bundleSize: Int) -> Int {
        guard bundleSize > 0 else { return 0 }
        let quotient = differencePieces / bundleSize
        if differencePieces < 0 && differencePieces % bundleSize != 0 {
            return quotient - 1
        }
        return quotient
    }
}
