import SwiftUI

struct TowerMapMarker: View {
    let name: String
    let colorHex: String?
    var isFocused: Bool = false

    @State private var pulse = false

    private var tint: Color {
        if let colorHex, let color = Color(hex: colorHex) {
            return color
        }
        return .cyan
    }

    var body: some View {
        ZStack {
            if isFocused {
                Circle()
                    .stroke(tint.opacity(0.65), lineWidth: 2)
                    .frame(width: pulse ? 52 : 30, height: pulse ? 52 : 30)
                    .opacity(pulse ? 0 : 0.85)
                    .animation(.easeOut(duration: 1.35).repeatForever(autoreverses: false), value: pulse)

                Circle()
                    .fill(tint.opacity(0.22))
                    .frame(width: 34, height: 34)
                    .scaleEffect(pulse ? 1.18 : 0.92)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
            }

            VStack(spacing: 2) {
                Text(name)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(tint.opacity(isFocused ? 1 : 0.88), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5))
                    .shadow(color: isFocused ? tint.opacity(0.45) : .clear, radius: 8, y: 2)

                Circle()
                    .fill(tint)
                    .frame(width: isFocused ? 12 : 10, height: isFocused ? 12 : 10)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.28), radius: 2, y: 1)
            }
        }
        .onAppear {
            guard isFocused else { return }
            pulse = true
        }
        .onChange(of: isFocused) { _, focused in
            pulse = focused
        }
    }
}
