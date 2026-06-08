import SwiftUI

enum KeyboardPinnedEditorMotion {
    static let lift = Animation.spring(response: 0.42, dampingFraction: 0.86)
    static let dismiss = Animation.spring(response: 0.38, dampingFraction: 0.9)
    static let crossfade = Animation.snappy(duration: 0.24)

    static var panelLiftTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    static var panelCrossfadeTransition: AnyTransition {
        .opacity
    }

    static var listCardLiftRemovalTransition: AnyTransition {
        .opacity
    }

    static var listCardLiftInsertionTransition: AnyTransition {
        .opacity
    }

    static var placeholderLiftInsertionTransition: AnyTransition {
        .opacity
    }

    static var placeholderLiftRemovalTransition: AnyTransition {
        .opacity
    }

    static var listCrossfadeTransition: AnyTransition {
        .opacity
    }
}

enum KeyboardEditingHaptics {
    static func lightImpact() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

struct KeyboardEditingPlaceholder: View {
    let itemName: String
    let accentColor: Color
    @Environment(AppThemeSettings.self) private var theme

    var body: some View {
        PremiumCard(accentColor: accentColor, style: .standard) {
            HStack(spacing: 10) {
                LinenItemIcon(itemName: itemName, size: 32, boxed: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(itemName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption2.weight(.bold))
                        Text("editing above")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(accentColor.opacity(0.82))
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accentColor.opacity(0.75))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                .stroke(accentColor.opacity(0.32), lineWidth: 1.5)
        }
        .opacity(0.58)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct KeyboardPinnedPanel<Content: View>: View {
    let itemName: String
    let editingIndex: Int
    let editingTotal: Int
    var contentTransition: AnyTransition = KeyboardPinnedEditorMotion.panelCrossfadeTransition
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .transition(contentTransition)
        }
        .background(.ultraThinMaterial)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Editing \(itemName), \(editingIndex + 1) of \(editingTotal)")
        .transition(KeyboardPinnedEditorMotion.panelLiftTransition)
    }
}

struct KeyboardEditingToolbar: View {
    let itemName: String?
    let canMovePrevious: Bool
    let canMoveNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDone: () -> Void

    var body: some View {
        Button {
            KeyboardEditingHaptics.lightImpact()
            onPrevious()
        } label: {
            Label("Previous", systemImage: "chevron.left")
        }
        .disabled(!canMovePrevious)

        Button {
            KeyboardEditingHaptics.lightImpact()
            onNext()
        } label: {
            Label("Next", systemImage: "chevron.right")
        }
        .disabled(!canMoveNext)

        Spacer()

        if let itemName {
            Text(itemName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: 120)
        }

        Button("Done", action: onDone)
    }
}
