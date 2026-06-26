import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct SectionHeader: View {
    public let title: String
    public var subtitle: String? = nil
    @Environment(AppThemeSettings.self) private var theme

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(theme.isPractical ? .headline.weight(.bold) : .title3.weight(.bold))
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(theme.secondaryTextOpacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
