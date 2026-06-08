import SwiftUI

enum PremiumCardStyle: Equatable {
    case standard
    case fullAccent
    case solid(Color)
}

struct PremiumCard<Content: View>: View {
    var accentColor: Color? = nil
    var style: PremiumCardStyle = .standard
    /// Elevates border, shadow, and accent glow when this card is the active/current focus.
    var isCurrent: Bool = false
    @ViewBuilder var content: () -> Content

    @Environment(AppThemeSettings.self) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var resolvedAccent: Color {
        accentColor ?? .white
    }

    var body: some View {
        VStack(spacing: 0) {
            content()
                .padding(responsivePadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: cardShape)
        .clipShape(cardShape)
        .contentShape(cardShape)
        .overlay(cardBorderOverlay)
        .overlay(alignment: .top) {
            if theme.showsCardAccentStrip, shouldShowAccentHairline {
                Capsule()
                    .fill(resolvedAccent.opacity(isCurrent ? 0.52 : 0.34))
                    .frame(height: isCurrent ? 1.5 : 1)
                    .padding(.horizontal, theme.cardPadding)
            }
        }
        .overlay {
            if isCurrent, accentColor != nil, !theme.isPractical {
                currentGlowOverlay
            }
        }
        .shadow(color: ambientShadowColor, radius: ambientShadowRadius, y: ambientShadowY)
        .shadow(color: keyShadowColor, radius: keyShadowRadius, y: keyShadowY)
        .scaleEffect(isCurrent && !theme.isPractical ? 1.008 : 1)
        .animation(cardMotion, value: isCurrent)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private var cardMotion: Animation? {
        reduceMotion ? nil : .snappy(duration: 0.28)
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

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
    }

    private var shouldShowAccentHairline: Bool {
        if theme.isPractical { return isCurrent && accentColor != nil }

        switch style {
        case .fullAccent:
            return true
        case .standard, .solid:
            return isCurrent && accentColor != nil
        }
    }

    @ViewBuilder
    private var cardBorderOverlay: some View {
        cardShape
            .stroke(borderFill, lineWidth: borderLineWidth)
    }

    private var borderLineWidth: CGFloat {
        if theme.isPractical {
            return isCurrent ? 1.4 : 1
        }
        return isCurrent ? 1.15 : 0.8
    }

    @ViewBuilder
    private var currentGlowOverlay: some View {
        cardShape
            .stroke(resolvedAccent.opacity(0.38), lineWidth: 1)
            .blur(radius: 2.5)
            .padding(-1)
            .allowsHitTesting(false)
    }

    private var ambientShadowColor: Color {
        guard theme.showsCardShadow else { return .clear }
        return Color.black.opacity(isCurrent ? 0.20 : 0.12)
    }

    private var ambientShadowRadius: CGFloat {
        theme.showsCardShadow ? (isCurrent ? 14 : 8) : 0
    }

    private var ambientShadowY: CGFloat {
        theme.showsCardShadow ? (isCurrent ? 7 : 4) : 0
    }

    private var keyShadowColor: Color {
        guard theme.showsCardShadow, isCurrent, let accentColor else { return .clear }
        return accentColor.opacity(theme.isPractical ? 0.14 : 0.22)
    }

    private var keyShadowRadius: CGFloat {
        isCurrent && theme.showsCardShadow ? 10 : 0
    }

    private var keyShadowY: CGFloat {
        isCurrent && theme.showsCardShadow ? 2 : 0
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
                let top = accentColor.opacity(isCurrent ? 0.26 : 0.20)
                let mid = accentColor.opacity(isCurrent ? 0.14 : 0.105)
                let bottom = Color.white.opacity(isCurrent ? 0.07 : 0.055)
                return LinearGradient(
                    colors: [top, mid, bottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            fallthrough
        case .standard:
            let accentWash = (accentColor ?? .white).opacity(
                accentColor == nil ? 0.035 : (isCurrent ? 0.068 : 0.052)
            )
            return LinearGradient(
                colors: [
                    Color.white.opacity(isCurrent ? 0.10 : 0.082),
                    accentWash,
                    Color.white.opacity(isCurrent ? 0.042 : 0.032)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var practicalCardColor: Color {
        switch style {
        case .solid(let color):
            return color.opacity(isCurrent ? 0.96 : 0.92)
        case .fullAccent:
            return (accentColor ?? .white).opacity(isCurrent ? 0.18 : 0.14)
        case .standard:
            return Color.white.opacity(isCurrent ? 0.11 : 0.08)
        }
    }

    private var borderFill: LinearGradient {
        if theme.isPractical {
            let base = Color.white.opacity(isCurrent ? 0.28 : 0.18)
            if isCurrent, let accentColor {
                return LinearGradient(
                    colors: [accentColor.opacity(0.42), base],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            return LinearGradient(colors: [base, base], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        switch style {
        case .solid:
            if let accentColor {
                let leading = accentColor.opacity(isCurrent ? 0.44 : 0.32)
                return LinearGradient(
                    colors: [leading, Color.white.opacity(isCurrent ? 0.12 : 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            return LinearGradient(
                colors: [
                    Color.white.opacity(isCurrent ? 0.18 : 0.14),
                    Color.white.opacity(isCurrent ? 0.08 : 0.055)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .fullAccent:
            if let accentColor {
                let leading = accentColor.opacity(isCurrent ? 0.58 : 0.48)
                return LinearGradient(
                    colors: [leading, Color.white.opacity(isCurrent ? 0.14 : 0.11)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            fallthrough
        case .standard:
            let leading = (accentColor ?? .white).opacity(
                accentColor == nil ? (isCurrent ? 0.17 : 0.13) : (isCurrent ? 0.34 : 0.24)
            )
            return LinearGradient(
                colors: [leading, Color.white.opacity(isCurrent ? 0.10 : 0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
