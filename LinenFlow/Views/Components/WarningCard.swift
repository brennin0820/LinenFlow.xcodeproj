import SwiftUI

struct WarningCard: View {
    let warnings: [String]
    @State private var isExpanded = false
    @Environment(AppThemeSettings.self) private var theme

    var body: some View {
        Group {
            if warnings.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        guard warnings.count > 1 else { return }
                        withAnimation(.snappy(duration: 0.18)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.bold))
                                .frame(width: 28, height: 28)
                                .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Check before continuing")
                                    .font(.subheadline.weight(.semibold))
                                if warnings.count > 1 {
                                    Text("\(warnings.count) warnings")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.58))
                                }
                            }
                            Spacer()
                            if warnings.count > 1 {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.48))
                            }
                        }
                    }
                    .foregroundStyle(.yellow.opacity(0.9))
                    .buttonStyle(.plain)
                    .accessibilityHint(warnings.count > 1 ? "Double tap to show warning details." : "")

                    if warnings.count == 1 || isExpanded {
                        ForEach(warnings, id: \.self) { warning in
                            Text("• \(warning)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(theme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.065), in: RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}
