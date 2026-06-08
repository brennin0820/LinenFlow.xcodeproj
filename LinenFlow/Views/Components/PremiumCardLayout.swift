import SwiftUI

struct PremiumCardActionRow<Leading: View, Trailing: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: spacing) {
                leading()
                Spacer(minLength: 8)
                trailing()
            }

            VStack(alignment: .leading, spacing: spacing) {
                leading()
                HStack {
                    Spacer(minLength: 0)
                    trailing()
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
