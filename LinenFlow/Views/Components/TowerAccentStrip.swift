import SwiftUI

struct TowerAccentStrip: View {
    let hex: String?
    var width: CGFloat = 4

    var body: some View {
        Rectangle()
            .fill(resolvedColor)
            .frame(width: width)
    }

    private var resolvedColor: Color {
        if let hex, let c = Color(hex: hex) { return c }
        return .blue
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
