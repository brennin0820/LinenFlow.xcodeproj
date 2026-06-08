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
            content()
                .padding(responsivePadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
        .clipShape(cardShape)
        .contentShape(cardShape)
        .overlay(
            cardShape
                .stroke(borderFill, lineWidth: theme.isPractical ? 1 : 0.8)
        )
        .overlay(alignment: .top) {
            if theme.showsCardAccentStrip, shouldShowAccentHairline, let accentColor {
                Capsule()
                    .fill(accentColor.opacity(0.34))
                    .frame(height: 1)
                    .padding(.horizontal, theme.cardPadding)
            }
        }
        .shadow(
            color: theme.showsCardShadow ? Color.black.opacity(0.14) : .clear,
            radius: theme.showsCardShadow ? 8 : 0,
            y: theme.showsCardShadow ? 4 : 0
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

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
    }

    private var shouldShowAccentHairline: Bool {
        if theme.isPractical { return false }

        switch style {
        case .fullAccent:
            return true
        case .standard, .solid:
            return false
        }
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
                        accentColor.opacity(0.20),
                        accentColor.opacity(0.105),
                        Color.white.opacity(0.055)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            fallthrough
        case .standard:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.082),
                    (accentColor ?? .white).opacity(accentColor == nil ? 0.035 : 0.052),
                    Color.white.opacity(0.032)
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
                    colors: [accentColor.opacity(0.32), Color.white.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            return LinearGradient(
                colors: [Color.white.opacity(0.14), Color.white.opacity(0.055)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .fullAccent:
            if let accentColor {
                return LinearGradient(
                    colors: [accentColor.opacity(0.48), Color.white.opacity(0.11)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            fallthrough
        case .standard:
            return LinearGradient(
                colors: [
                    (accentColor ?? .white).opacity(accentColor == nil ? 0.13 : 0.24),
                    Color.white.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
