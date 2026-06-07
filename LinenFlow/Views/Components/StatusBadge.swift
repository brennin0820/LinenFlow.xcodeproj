import SwiftUI

struct StatusBadge: View {
    let status: CalculationStatus

    var body: some View {
        Label(status.displayName, systemImage: icon)
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.22), color.opacity(0.11)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay(Capsule().stroke(color.opacity(0.24), lineWidth: 1))
            .foregroundStyle(color)
            .accessibilityLabel("Status: \(status.displayName)")
    }

    private var icon: String {
        switch status {
        case .shortage: return "exclamationmark.triangle.fill"
        case .overage:  return "checkmark.circle.fill"
        case .exact:    return "equal.circle.fill"
        }
    }

    var color: Color {
        switch status {
        case .shortage: return .red
        case .overage:  return .green
        case .exact:    return .blue
        }
    }
}
