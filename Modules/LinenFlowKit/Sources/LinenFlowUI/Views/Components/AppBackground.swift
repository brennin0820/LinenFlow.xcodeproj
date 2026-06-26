import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct AppBackground<Content: View>: View {
    public var accentColor: Color? = nil
    @ViewBuilder public var content: () -> Content
    @Environment(AppThemeSettings.self) private var theme

    public var body: some View {
        ZStack {
            if theme.usesBackgroundGradients {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.07),
                        Color(red: 0.09, green: 0.08, blue: 0.12),
                        Color(red: 0.06, green: 0.09, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.07),
                        Color.pink.opacity(0.045),
                        Color.orange.opacity(0.045),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            } else {
                Color(red: 0.07, green: 0.07, blue: 0.09)
                    .ignoresSafeArea()
            }

            if theme.usesAccentBackgroundWash, let color = accentColor {
                LinearGradient(
                    colors: [
                        color.opacity(0.18),
                        color.opacity(0.08),
                        Color.mint.opacity(0.035),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .transition(.opacity)
                .allowsHitTesting(false)
            }

            content()
        }
    }
}
