import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum KeyboardEditingLayout {
    /// Visible gap between the active card bottom edge and the keyboard top.
    static let keyboardGap: CGFloat = 16
}

private struct LinenFocusedCardMaxHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    /// Max height for scrollable focused card content (set by `HomeView` when keyboard is visible).
    var linenFocusedCardMaxHeight: CGFloat? {
        get { self[LinenFocusedCardMaxHeightKey.self] }
        set { self[LinenFocusedCardMaxHeightKey.self] = newValue }
    }
}

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

enum KeyboardEditingFocus {
    /// Dismisses the software keyboard without clearing edit mode or `focusedItemID`.
    static func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
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
        PremiumCard(accentColor: accentColor, style: .standard, isCurrent: true) {
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

/// Absorbs background taps: dismisses the keyboard only — never clears `focusedItemID` or edit mode.
/// Prefer this over `allowsHitTesting(false)` on dimmed cards, which lets hits fall through to cards behind.
struct KeyboardEditingTapAbsorber: ViewModifier {
    let isActive: Bool
    var dimmed: Bool = false

    func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                Color.black.opacity(dimmed ? 0.22 : 0.001)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        KeyboardEditingFocus.dismissKeyboard()
                    }
                    .accessibilityHidden(true)
            }
        }
    }
}

extension View {
    func keyboardEditingTapAbsorber(isActive: Bool, dimmed: Bool = false) -> some View {
        modifier(KeyboardEditingTapAbsorber(isActive: isActive, dimmed: dimmed))
    }

    /// Tracks software-keyboard overlap from the bottom of the key window (animated with keyboard).
    func observesKeyboardBottomInset(_ inset: Binding<CGFloat>, reduceMotion: Bool = false) -> some View {
        modifier(KeyboardBottomInsetObserver(bottomInset: inset, reduceMotion: reduceMotion))
    }
}

private struct KeyboardBottomInsetObserver: ViewModifier {
    @Binding var bottomInset: CGFloat
    var reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                applyInset(from: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
                withAnimation(keyboardAnimation(from: notification)) {
                    bottomInset = 0
                }
            }
    }

    private func applyInset(from notification: Notification) {
        #if canImport(UIKit)
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
        else { return }

        let converted = window.convert(frame, from: nil)
        let overlap = max(0, window.bounds.maxY - converted.minY)
        withAnimation(keyboardAnimation(from: notification)) {
            bottomInset = overlap
        }
        #endif
    }

    private func keyboardAnimation(from notification: Notification) -> Animation? {
        if reduceMotion { return nil }
        #if canImport(UIKit)
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        return .easeInOut(duration: duration)
        #else
        return KeyboardPinnedEditorMotion.lift
        #endif
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
