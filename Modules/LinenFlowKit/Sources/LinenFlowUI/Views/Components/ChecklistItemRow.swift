import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct ChecklistItemRow: View {
    public let item: LeavingChecklistItem
    public let isChecked: Bool
    public let onToggle: () -> Void

    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? .green : .white.opacity(0.38))
                    .animation(.snappy(duration: 0.18), value: isChecked)

                Text(item.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isChecked ? .white.opacity(0.5) : .white)
                    .strikethrough(isChecked, color: .white.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.snappy(duration: 0.18), value: isChecked)

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}

public struct ChecklistItemEditRow: View {
    public let item: LeavingChecklistItem
    public let onToggleEnabled: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(item.isEnabled ? .blue : .white.opacity(0.25))

            Text(item.title)
                .font(.body.weight(.medium))
                .foregroundStyle(item.isEnabled ? .white : .white.opacity(0.45))

            Spacer()

            Button(action: onToggleEnabled) {
                Label(item.isEnabled ? "Enabled" : "Disabled", systemImage: item.isEnabled ? "checkmark" : "minus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.isEnabled ? .blue : .white.opacity(0.4))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        item.isEnabled ? Color.blue.opacity(0.15) : Color.white.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
    }
}
