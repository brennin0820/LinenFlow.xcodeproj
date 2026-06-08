import SwiftUI

enum PremiumCardStyle: Equatable {
    case standard
    case fullAccent
    case solid(Color)
}

struct PremiumCard<Content: View>: View {
    var accentColor: Color? = nil
    var style: PremiumCardStyle = .standard
    @ViewBuilder var content: () -> Content
    @Environment(AppThemeSettings.self) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            if theme.showsCardAccentStrip, let accentColor {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.55)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 4)
            }
            content()
                .padding(responsivePadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                .stroke(borderFill, lineWidth: 1)
        )
        .overlay(alignment: .top) {
            if theme.usesGlassCardFill {
                RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .blendMode(.plusLighter)
            }
        }
        .shadow(
            color: theme.showsCardShadow ? Color.black.opacity(0.22) : .clear,
            radius: theme.showsCardShadow ? 12 : 0,
            y: theme.showsCardShadow ? 6 : 0
        )
    }

    private var responsivePadding: CGFloat {
        var padding = theme.cardPadding
        if horizontalSizeClass == .regular {
            padding += 2
        }
        if dynamicTypeSize.isAccessibilitySize {
            padding = max(10, padding - 4)
        }
        return padding
    }

    private var cardFill: LinearGradient {
        if theme.isPractical {
            let fill = practicalCardColor
            return LinearGradient(colors: [fill, fill], startPoint: .top, endPoint: .bottom)
        }

        switch style {
        case .solid(let color):
            return LinearGradient(colors: [color, color], startPoint: .top, endPoint: .bottom)
        case .fullAccent:
            if let accentColor {
                return LinearGradient(
                    colors: [
                        accentColor.opacity(0.34),
                        accentColor.opacity(0.20),
                        accentColor.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            fallthrough
        case .standard:
            return LinearGradient(
                colors: [
                    (accentColor ?? .white).opacity(accentColor == nil ? 0.075 : 0.12),
                    Color.white.opacity(0.055),
                    Color(red: 0.11, green: 0.13, blue: 0.16).opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var practicalCardColor: Color {
        switch style {
        case .solid(let color):
            return color.opacity(0.92)
        case .fullAccent:
            return (accentColor ?? .white).opacity(0.14)
        case .standard:
            return Color.white.opacity(0.08)
        }
    }

    private var borderFill: LinearGradient {
        if theme.isPractical {
            let stroke = Color.white.opacity(0.18)
            return LinearGradient(colors: [stroke, stroke], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        switch style {
        case .solid:
            if let accentColor {
                return LinearGradient(
                    colors: [accentColor.opacity(0.45), accentColor.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            return LinearGradient(
                colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .fullAccent:
            if let accentColor {
                return LinearGradient(
                    colors: [accentColor.opacity(0.6), accentColor.opacity(0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            fallthrough
        case .standard:
            return LinearGradient(
                colors: [
                    (accentColor ?? .white).opacity(accentColor == nil ? 0.12 : 0.34),
                    Color.white.opacity(0.075)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
