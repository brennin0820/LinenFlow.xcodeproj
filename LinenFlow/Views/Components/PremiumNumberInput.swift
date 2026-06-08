import SwiftUI

/// Labeled numeric input with calculator-style expression entry (`245*2`, `60+60`).
/// Wraps `PremiumExpressionInput` and binds the evaluated result to `value`.
struct PremiumNumberInput: View {
    let label: String
    @Binding var value: Int
    var suffix: String? = nil
    var placeholder: String = "0"
    var requestsFocusOnAppear = false
    var focusRequest: Int = 0
    var focusReleaseRequest: Int = 0
    var showArithmeticKeys: Bool = false
    var onFocusChange: ((Bool) -> Void)? = nil
    var onCommit: ((Int) -> Void)? = nil

    @State private var expression: String = ""
    @State private var isFocused = false

    var body: some View {
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
