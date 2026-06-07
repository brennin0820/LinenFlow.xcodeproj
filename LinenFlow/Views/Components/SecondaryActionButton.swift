import SwiftUI

struct SecondaryActionButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void
    @Environment(AppThemeSettings.self) private var theme

    var body: some View {
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
            .frame(minHeight: 50)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .background(theme.secondaryButtonFill, in: RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(theme.isPractical ? 0.22 : 0.11), lineWidth: 1)
            )
        }
        .buttonStyle(SecondaryPolishedButtonStyle(usesPressScale: theme.usesPressScaleAnimation))
        .accessibilityLabel(title)
    }
}

private struct SecondaryPolishedButtonStyle: ButtonStyle {
    let usesPressScale: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(usesPressScale && configuration.isPressed ? 0.975 : 1)
            .brightness(configuration.isPressed ? -0.035 : 0)
            .animation(usesPressScale ? .snappy(duration: 0.16) : nil, value: configuration.isPressed)
    }
}
