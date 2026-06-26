import SwiftUI
import UIKit
import Observation

public enum AppThemeMode: String, CaseIterable, Identifiable, Codable {
    case beautiful
    case practical

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .beautiful: return "Beautiful"
        case .practical: return "Practical"
        }
    }

    public var subtitle: String {
        switch self {
        case .beautiful:
            return "Gradients, glass cards, and tower accent washes."
        case .practical:
            return "Flat surfaces, stronger contrast, less decoration."
        }
    }

    public var systemImage: String {
        switch self {
        case .beautiful: return "sparkles"
        case .practical: return "checklist"
        }
    }
}

@Observable
public final class AppThemeSettings {
    public static let storageKey = "appTheme.mode"

    public var mode: AppThemeMode {
        didSet {
            guard mode != oldValue else { return }
            UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
            Self.applyTabBarAppearance(for: mode)
        }
    }

    public init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppThemeMode.beautiful.rawValue
        mode = AppThemeMode(rawValue: raw) ?? .beautiful
        Self.applyTabBarAppearance(for: mode)
    }

    public var isPractical: Bool { mode == .practical }

    public var cardCornerRadius: CGFloat { isPractical ? 8 : 12 }
    public var cardPadding: CGFloat { isPractical ? 14 : 16 }
    public var showsCardShadow: Bool { !isPractical }
    public var showsCardAccentStrip: Bool { !isPractical }
    public var usesGlassCardFill: Bool { !isPractical }
    public var usesBackgroundGradients: Bool { !isPractical }
    public var usesAccentBackgroundWash: Bool { !isPractical }
    public var usesButtonGradients: Bool { !isPractical }
    public var usesButtonShadow: Bool { !isPractical }
    public var usesPressScaleAnimation: Bool { !isPractical }
    public var usesNumericTransitions: Bool { !isPractical }

    public var secondaryTextOpacity: Double { isPractical ? 0.78 : 0.6 }

    public var primaryButtonColor: Color { isPractical ? Color(red: 0.10, green: 0.48, blue: 0.98) : .cyan }
    public var secondaryButtonFill: Color {
        isPractical ? Color.white.opacity(0.10) : Color.white.opacity(0.065)
    }

    public var tabBarSelectedColor: UIColor {
        isPractical ? UIColor(red: 0.10, green: 0.48, blue: 0.98, alpha: 1) : UIColor.systemCyan
    }

    public static func applyTabBarAppearance(for mode: AppThemeMode) {
        let appearance = UITabBarAppearance()
        let selectedColor = mode == .practical
            ? UIColor(red: 0.10, green: 0.48, blue: 0.98, alpha: 1)
            : UIColor.systemCyan
        let normalColor = UIColor.white.withAlphaComponent(mode == .practical ? 0.72 : 0.56)

        if mode == .practical {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1)
            appearance.shadowColor = UIColor.white.withAlphaComponent(0.08)
        } else {
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.28)
            appearance.shadowColor = UIColor.white.withAlphaComponent(0.08)
        }

        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
