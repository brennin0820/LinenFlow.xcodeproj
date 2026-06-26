import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct StickyBottomActionBar<Content: View>: View {
    @ViewBuilder public var content: () -> Content

    public var body: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.08))
            VStack(spacing: 8) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.08), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 28)
                .allowsHitTesting(false)
            }
        }
    }
}
