import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct PremiumCardActionRow<Leading: View, Trailing: View>: View {
    public var spacing: CGFloat = 12
    @ViewBuilder public var leading: () -> Leading
    @ViewBuilder public var trailing: () -> Trailing

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: spacing) {
                leading()
                    .layoutPriority(1)
                Spacer(minLength: 10)
                trailing()
                    .fixedSize(horizontal: true, vertical: false)
            }

            VStack(alignment: .leading, spacing: spacing) {
                leading()
                HStack {
                    Spacer(minLength: 0)
                    trailing()
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }
}

public struct PremiumCardAdaptiveGrid<Content: View>: View {
    public var spacing: CGFloat = 8
    public var columnCount: Int = 2
    @ViewBuilder public var content: () -> Content

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) {
                content()
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: spacing),
                    count: columnCount
                ),
                spacing: spacing
            ) {
                content()
            }
        }
    }
}
