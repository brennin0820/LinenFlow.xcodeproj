import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct MetricTile: View {
    public let label: String
    public let value: String
    public var secondary: String? = nil
    public var tint: Color = .white
    public var explanation: String? = nil

    @Environment(AppThemeSettings.self) private var theme
    @State private var isExplanationVisible = false

    private var isInteractive: Bool { explanation != nil }

    private var accessibilityLabelText: String {
        var parts = ["\(label), \(value)"]
        if let secondary { parts.append(secondary) }
        if isExplanationVisible, let explanation { parts.append(explanation) }
        return parts.joined(separator: ", ")
    }

    public var body: some View {
        let content = VStack(spacing: 4) {
            HStack {
                Spacer(minLength: 0)
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(theme.secondaryTextOpacity))
                    .tracking(theme.isPractical ? 0.4 : 0.8)
                if isInteractive {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(isExplanationVisible ? 0.7 : 0.3))
                }
                Spacer(minLength: 0)
            }
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .modifier(OptionalNumericTextTransition(isEnabled: theme.usesNumericTransitions, value: value))
                .frame(maxWidth: .infinity)
            if let secondary {
                Text(secondary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(theme.secondaryTextOpacity))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .multilineTextAlignment(.center)
            }
            if isExplanationVisible, let explanation {
                Text(explanation)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(tileFill, in: RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                .stroke(tint.opacity(tint == .white ? (theme.isPractical ? 0.14 : 0.08) : 0.18), lineWidth: 1)
        )
        .animation(theme.usesPressScaleAnimation ? .snappy(duration: 0.2) : nil, value: isExplanationVisible)

        if isInteractive {
            Button {
                isExplanationVisible.toggle()
            } label: {
                content
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabelText)
            .accessibilityHint(isExplanationVisible ? "Double tap to hide explanation." : "Double tap to show explanation.")
        } else {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabelText)
        }
    }

    private var tileFill: LinearGradient {
        if theme.isPractical {
            let fill = Color.white.opacity(0.08)
            return LinearGradient(colors: [fill, fill], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        return LinearGradient(
            colors: [
                tint.opacity(tint == .white ? 0.05 : 0.12),
                Color.white.opacity(0.045)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct OptionalNumericTextTransition: ViewModifier {
    public let isEnabled: Bool
    public let value: String

    public func body(content: Content) -> some View {
        if isEnabled {
            content
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        } else {
            content
        }
    }
}
