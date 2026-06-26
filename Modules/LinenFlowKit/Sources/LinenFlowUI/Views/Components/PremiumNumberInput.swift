import SwiftUI
import LinenFlowCore
import LinenFlowEngine

/// Labeled numeric input with calculator-style expression entry (`245*2`, `60+60`).
/// Wraps `PremiumExpressionInput` and binds the evaluated result to `value`.
public struct PremiumNumberInput: View {
    public let label: String
    @Binding public var value: Int
    public var suffix: String? = nil
    public var placeholder: String = "0"
    public var requestsFocusOnAppear = false
    public var focusRequest: Int = 0
    public var focusReleaseRequest: Int = 0
    public var showArithmeticKeys: Bool = false
    public var onFocusChange: ((Bool) -> Void)? = nil
    public var onCommit: ((Int) -> Void)? = nil

    @State private var expression: String = ""
    @State private var isFocused = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if !label.isEmpty {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            PremiumExpressionInput(
                label: "",
                expression: $expression,
                evaluated: $value,
                suffix: suffix,
                placeholder: placeholder,
                requestsFocusOnAppear: requestsFocusOnAppear,
                focusRequest: focusRequest,
                focusReleaseRequest: focusReleaseRequest,
                showArithmeticKeys: showArithmeticKeys,
                onFocusChange: { focused in
                    isFocused = focused
                    onFocusChange?(focused)
                },
                onCommit: onCommit
            )
        }
        .onAppear {
            syncExpressionFromValue(value)
        }
        .onChange(of: value) { _, newValue in
            guard !isFocused else { return }
            syncExpressionFromValue(newValue)
        }
    }

    private func syncExpressionFromValue(_ newValue: Int) {
        if newValue == 0 {
            if expression.trimmingCharacters(in: .whitespaces).isEmpty {
                return
            }
            expression = ""
            return
        }
        switch ArithmeticExpressionService.evaluatePieces(expression) {
        case .success(let evaluated) where evaluated == newValue:
            return
        default:
            expression = "\(newValue)"
        }
    }
}
