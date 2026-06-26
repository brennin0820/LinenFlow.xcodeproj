import SwiftUI
import LinenFlowCore
import LinenFlowEngine

/// Compact operator buttons for pinned expression editing (`245*2`, `(245*2)+60`).
public struct ArithmeticKeypadStrip: View {
    public var onInsert: (String) -> Void

    private struct Key: Identifiable {
        public let id: String
        public let display: String
        public let insert: String
        public let accessibilityLabel: String
    }

    private let keys: [Key] = [
        Key(id: "+", display: "+", insert: "+", accessibilityLabel: "Plus"),
        Key(id: "-", display: "−", insert: "-", accessibilityLabel: "Minus"),
        Key(id: "*", display: "×", insert: "*", accessibilityLabel: "Multiply"),
        Key(id: "/", display: "÷", insert: "/", accessibilityLabel: "Divide"),
        Key(id: "(", display: "(", insert: "(", accessibilityLabel: "Open parenthesis"),
        Key(id: ")", display: ")", insert: ")", accessibilityLabel: "Close parenthesis"),
        Key(id: ".", display: ".", insert: ".", accessibilityLabel: "Multiply"),
    ]

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(keys) { key in
                Button {
                    KeyboardEditingHaptics.lightImpact()
                    onInsert(key.insert)
                } label: {
                    Text(key.display)
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.88))
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(ArithmeticKeyButtonStyle())
                .accessibilityLabel(key.accessibilityLabel)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Arithmetic operators")
    }
}

private struct ArithmeticKeyButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? Color.blue.opacity(0.22) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}
