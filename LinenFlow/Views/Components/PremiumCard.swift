import SwiftUI

private struct LinenEditingActiveKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// When true, only `PremiumCard(isCurrent: true)` accepts taps; all other cards are inert.
    var linenEditingActive: Bool {
        get { self[LinenEditingActiveKey.self] }
        set { self[LinenEditingActiveKey.self] = newValue }
    }
}

enum PremiumCardStyle: Equatable {
    case standard
    case fullAccent
    case solid(Color)
}

struct PremiumCard<Content: View>: View {
    var accentColor: Color? = nil
    var style: PremiumCardStyle = .standard
    /// Elevates border and shadow when this card is the active/current focus.
    var isCurrent: Bool = false
    @ViewBuilder var content: () -> Content

    @Environment(AppThemeSettings.self) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.linenEditingActive) private var linenEditingActive

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
        .overlay { cardBorderOverlay.allowsHitTesting(false) }
        .overlay(alignment: .top) {
            if theme.showsCardAccentStrip, shouldShowAccentHairline {
                Capsule()
                    .fill(resolvedAccent.opacity(isCurrent ? 0.28 : 0.18))
                    .frame(height: 1)
                    .padding(.horizontal, theme.cardPadding)
                    .allowsHitTesting(false)
            }
        }
        .shadow(color: ambientShadowColor, radius: ambientShadowRadius, y: ambientShadowY)
        .animation(cardMotion, value: isCurrent)
        .allowsHitTesting(allowsCardInteraction)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    /// During inline editing, only the current card should receive taps.
    private var allowsCardInteraction: Bool {
        !linenEditingActive || isCurrent
    }

    private var cardMotion: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.18)
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
            return isCurrent ? 1.2 : 1
        }
        return isCurrent ? 1 : 0.65
    }

    private var ambientShadowColor: Color {
        guard theme.showsCardShadow else { return .clear }
        return Color.black.opacity(isCurrent ? 0.13 : 0.07)
    }

    private var ambientShadowRadius: CGFloat {
        theme.showsCardShadow ? (isCurrent ? 9 : 5) : 0
    }

    private var ambientShadowY: CGFloat {
        theme.showsCardShadow ? (isCurrent ? 4 : 2) : 0
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
                let top = accentColor.opacity(isCurrent ? 0.20 : 0.16)
                let mid = accentColor.opacity(isCurrent ? 0.10 : 0.08)
                let bottom = Color.white.opacity(isCurrent ? 0.05 : 0.04)
                return LinearGradient(
                    colors: [top, mid, bottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            fallthrough
        case .standard:
            let accentWash = (accentColor ?? .white).opacity(
                accentColor == nil ? 0.025 : (isCurrent ? 0.045 : 0.035)
            )
            return LinearGradient(
                colors: [
                    Color.white.opacity(isCurrent ? 0.07 : 0.06),
                    accentWash,
                    Color.white.opacity(isCurrent ? 0.03 : 0.025)
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
            let base = Color.white.opacity(isCurrent ? 0.20 : 0.14)
            if isCurrent, let accentColor {
                return LinearGradient(
                    colors: [accentColor.opacity(0.28), base],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            return LinearGradient(colors: [base, base], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        switch style {
        case .solid:
            if let accentColor {
                let leading = accentColor.opacity(isCurrent ? 0.24 : 0.18)
                return LinearGradient(
                    colors: [leading, Color.white.opacity(isCurrent ? 0.06 : 0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            return LinearGradient(
                colors: [
                    Color.white.opacity(isCurrent ? 0.12 : 0.10),
                    Color.white.opacity(isCurrent ? 0.055 : 0.045)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .fullAccent:
            if let accentColor {
                let leading = accentColor.opacity(isCurrent ? 0.36 : 0.28)
                return LinearGradient(
                    colors: [leading, Color.white.opacity(isCurrent ? 0.09 : 0.07)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            fallthrough
        case .standard:
            let leading = (accentColor ?? .white).opacity(
                accentColor == nil ? (isCurrent ? 0.12 : 0.10) : (isCurrent ? 0.22 : 0.16)
            )
            return LinearGradient(
                colors: [leading, Color.white.opacity(isCurrent ? 0.07 : 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
