import SwiftUI

struct PremiumNumberInput: View {
    let label: String
    @Binding var value: Int
    var suffix: String? = nil
    var requestsFocusOnAppear = false
    var focusRequest: Int = 0
    var focusReleaseRequest: Int = 0
    var onFocusChange: ((Bool) -> Void)? = nil

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 8) {
                TextField("0", text: $text)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: text) { _, new in
                        let filtered = new.filter(\.isNumber)
                        if filtered != new { text = filtered }
                        value = Int(filtered) ?? 0
                    }
                if let suffix {
                    Text(suffix).font(.caption).foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .onAppear {
            if value > 0, text.isEmpty { text = String(value) }
            if requestsFocusOnAppear {
                isFocused = true
            }
        }
        .onChange(of: focusRequest) { _, _ in
            isFocused = true
        }
        .onChange(of: focusReleaseRequest) { _, _ in
            isFocused = false
        }
        .onChange(of: isFocused) { _, focused in
            onFocusChange?(focused)
        }
    }
}
