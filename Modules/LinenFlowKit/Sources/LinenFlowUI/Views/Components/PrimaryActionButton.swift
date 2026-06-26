import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct PrimaryActionButton: View {
    public let title: String
    public var systemImage: String? = nil
    public var isEnabled: Bool = true
    public let action: () -> Void
    @Environment(AppThemeSettings.self) private var theme

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.semibold))
                }
                Text(title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .background(buttonFill, in: RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.16 : 0.08), lineWidth: 1)
            )
            .shadow(
                color: theme.usesButtonShadow && isEnabled ? theme.primaryButtonColor.opacity(0.22) : .clear,
                radius: theme.usesButtonShadow ? 10 : 0,
                y: theme.usesButtonShadow ? 4 : 0
            )
        }
        .buttonStyle(PolishedButtonStyle(isEnabled: isEnabled, usesPressScale: theme.usesPressScaleAnimation))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.7)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isEnabled ? .isButton : [.isButton, .isStaticText])
    }

    private var buttonFill: LinearGradient {
        if theme.usesButtonGradients {
            return LinearGradient(
                colors: isEnabled
                    ? [Color.cyan, Color.blue, Color.purple.opacity(0.86)]
                    : [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        let enabledColor = theme.primaryButtonColor
        let disabledColor = Color.white.opacity(0.12)
        let fill = isEnabled ? enabledColor : disabledColor
        return LinearGradient(colors: [fill, fill], startPoint: .leading, endPoint: .trailing)
    }
}

private struct PolishedButtonStyle: ButtonStyle {
    public let isEnabled: Bool
    public let usesPressScale: Bool

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(usesPressScale && configuration.isPressed && isEnabled ? 0.975 : 1)
            .brightness(configuration.isPressed && isEnabled ? -0.04 : 0)
            .animation(usesPressScale ? .snappy(duration: 0.16) : nil, value: configuration.isPressed)
    }
}
