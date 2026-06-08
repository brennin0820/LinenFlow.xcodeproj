import SwiftUI

/// Numeric input that also accepts simple arithmetic (`245*11`, `60+60`, `(245*2)+60`).
/// The raw expression stays visible; the evaluated whole-piece value updates a separate binding.
struct PremiumExpressionInput: View {
    let label: String
    @Binding var expression: String
    @Binding var evaluated: Int
    var suffix: String? = nil
    var placeholder: String = "e.g. 245.2"
    var requestsFocusOnAppear = false
    var focusRequest: Int = 0
    var focusReleaseRequest: Int = 0
    var showArithmeticKeys: Bool = false
    var onFocusChange: ((Bool) -> Void)? = nil

    @State private var liveError: ArithmeticError?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            inputField
            if showArithmeticKeys {
                ArithmeticKeypadStrip { token in
                    appendToken(token)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            statusLine
        }
        .onAppear {
            recompute(expression)
            if requestsFocusOnAppear {
                isFocused = true
            }
        }
        .onChange(of: focusRequest) { _, _ in
            isFocused = true
        }
        .onChange(of: focusReleaseRequest) { _, _ in
            isFocused = false
        }
        .onChange(of: isFocused) { _, focused in
            onFocusChange?(focused)
        }
    }

    private var inputField: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $expression)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .focused($isFocused)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: expression) { old, new in
                    let filtered = ArithmeticInputRules.filter(new, previous: old)
                    if filtered != new {
                        expression = filtered
                        return
                    }
                    recompute(new)
                }
                .onSubmit {
                    recompute(expression)
                    isFocused = false
                }
            if let suffix {
                Text(suffix)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(isFocused ? 0.08 : 0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isFocused ? Color.blue.opacity(0.75) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusLine: some View {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        if let liveError {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(message(for: liveError))
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.red.opacity(0.88))
        } else if !trimmed.isEmpty {
            // If the user typed a plain integer, the green computed line is redundant; hide it.
            if Int(trimmed) != nil {
                EmptyView()
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "equal.circle.fill")
                    Text("\(evaluated) pcs")
                        .monospacedDigit()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green.opacity(0.88))
            }
        } else {
            EmptyView()
        }
    }

    private func appendToken(_ token: String) {
        guard ArithmeticInputRules.canAppend(token, to: expression) else { return }
        expression.append(token)
    }

    private func recompute(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            evaluated = 0
            liveError = nil
            return
        }
        switch ArithmeticExpressionService.evaluatePieces(input) {
        case .success(let v):
            evaluated = v
            liveError = nil
        case .failure(let err):
            liveError = err
        }
    }

    private func message(for err: ArithmeticError) -> String {
        switch err {
        case .empty: return "Enter a value."
        case .invalidCharacter(let c): return "Invalid character '\(c)'."
        case .partial: return "Incomplete expression."
        case .mismatchedParens: return "Mismatched parentheses."
        case .multipleDotMultipliers: return "Use one \".\" multiply (e.g. 245.2)."
        case .multipleGroupedExpressions: return "Add +, −, ×, or ÷ between parts."
        case .divisionByZero: return "Cannot divide by zero."
        case .negativeNotAllowed: return "Pieces must be 0 or more."
        case .fractionalNotAllowed: return "Pieces must be a whole number."
        }
    }
}
