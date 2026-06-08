import SwiftUI

struct PremiumCardActionRow<Leading: View, Trailing: View>: View {
    var spacing: CGFloat = 12
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
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

struct PremiumCardAdaptiveGrid<Content: View>: View {
    var spacing: CGFloat = 8
    var columnCount: Int = 2
    @ViewBuilder var content: () -> Content

    var body: some View {
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
