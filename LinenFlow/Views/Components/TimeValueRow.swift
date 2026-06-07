import SwiftUI

struct TimeValueRow: View {
    let label: String
    let time: Date?
    var tint: Color = .white
    var isProminent: Bool = false
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let icon = systemImage {
                Image(systemName: icon)
                    .font(isProminent ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 22, height: 22)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            Text(label)
                .font(isProminent ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(isProminent ? .white : .white.opacity(0.78))
                .lineLimit(1)

            Spacer()

            if let time {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(isProminent ? .title3.weight(.bold).monospacedDigit() : .subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(isProminent ? tint : .white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: time)
            } else {
                Text("—")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(.vertical, isProminent ? 10 : 7)
    }
}
