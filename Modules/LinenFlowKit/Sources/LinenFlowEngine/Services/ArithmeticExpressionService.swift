import Foundation
import LinenFlowCore

public enum ArithmeticExpressionService {
    /// Generic evaluation — returns a `Double` value or a parse error.
    public static func evaluate(_ input: String) -> Result<Double, ArithmeticError> {
        ArithmeticParser.parse(input)
    }

    public static func displayString(for value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
    }

    /// Evaluation in a "received pieces" context: result must be a non-negative whole integer.
    public static func evaluatePieces(_ input: String) -> Result<Int, ArithmeticError> {
        switch evaluate(input) {
        case .failure(let err):
            return .failure(err)
        case .success(let value):
            if value < 0 { return .failure(.negativeNotAllowed) }
            if value.truncatingRemainder(dividingBy: 1) != 0 {
                return .failure(.fractionalNotAllowed)
            }
            return .success(Int(value))
        }
    }
}
