import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct CollapsibleSection<Content: View>: View {
    public let title: String
    public let systemImage: String
    public let tint: Color
    @Binding public var isExpanded: Bool
    @ViewBuilder public var content: () -> Content

    public var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.snappy(duration: 0.22)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                        .frame(width: 28, height: 28)
                        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(0.18), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityHint(isExpanded ? "Double tap to collapse." : "Double tap to expand.")

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.snappy(duration: 0.22), value: isExpanded)
    }
}
