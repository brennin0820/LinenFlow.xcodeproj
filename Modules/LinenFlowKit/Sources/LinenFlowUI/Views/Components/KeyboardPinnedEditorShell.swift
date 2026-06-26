import SwiftUI
#if canImport(UIKit)
import UIKit
import LinenFlowCore
import LinenFlowEngine
#endif

public enum KeyboardEditingLayout {
    /// Visible gap between the active card bottom edge and the keyboard top.
    public static let keyboardGap: CGFloat = 16
}

private struct LinenFocusedCardMaxHeightKey: EnvironmentKey {
    public static let defaultValue: CGFloat? = nil
}

public extension EnvironmentValues {
    /// Max height for scrollable focused card content (set by `HomeView` when keyboard is visible).
    public var linenFocusedCardMaxHeight: CGFloat? {
        get { self[LinenFocusedCardMaxHeightKey.self] }
        set { self[LinenFocusedCardMaxHeightKey.self] = newValue }
    }
}

public enum KeyboardPinnedEditorMotion {
    public static let lift = Animation.spring(response: 0.42, dampingFraction: 0.86)
}

public enum KeyboardEditingFocus {
    /// Dismisses the software keyboard without clearing edit mode or `focusedItemID`.
    public static func dismissKeyboard() {
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

public enum KeyboardEditingHaptics {
    public static func lightImpact() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    public static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

public struct KeyboardEditingTapAbsorber: ViewModifier {
    public let isActive: Bool
    public var dimmed: Bool = false

    public func body(content: Content) -> some View {
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

public extension View {
    public func keyboardEditingTapAbsorber(isActive: Bool, dimmed: Bool = false) -> some View {
        modifier(KeyboardEditingTapAbsorber(isActive: isActive, dimmed: dimmed))
    }

    /// Tracks software-keyboard overlap from the bottom of the key window (animated with keyboard).
    public func observesKeyboardBottomInset(_ inset: Binding<CGFloat>, reduceMotion: Bool = false) -> some View {
        modifier(KeyboardBottomInsetObserver(bottomInset: inset, reduceMotion: reduceMotion))
    }
}

private struct KeyboardBottomInsetObserver: ViewModifier {
    @Binding public var bottomInset: CGFloat
    public var reduceMotion: Bool

    public func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                applyInset(from: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                bottomInset = 0
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
        // Avoid animating scroll padding with the keyboard — animated layout shifts resign the TextField.
        bottomInset = overlap
        #endif
    }
}

public struct KeyboardEditingToolbar: View {
    public let itemName: String?
    public let canMovePrevious: Bool
    public let canMoveNext: Bool
    public let onPrevious: () -> Void
    public let onNext: () -> Void
    public let onDone: () -> Void

    public var body: some View {
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
