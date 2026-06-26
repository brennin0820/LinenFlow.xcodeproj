import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct FoldedTowelIcon: View {
    public let color: Color

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                    .fill(color.opacity(0.78))
                    .frame(width: w * 0.9, height: h * 0.64)
                    .offset(x: -w * 0.03, y: -h * 0.02)
                RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
                    .stroke(Color.white.opacity(0.58), lineWidth: max(1, w * 0.07))
                    .frame(width: w * 0.44, height: h * 0.52)
                    .offset(x: w * 0.02, y: -h * 0.01)
                Capsule()
                    .fill(Color.white.opacity(0.44))
                    .frame(width: w * 0.62, height: max(1.5, h * 0.08))
                    .offset(x: -w * 0.16, y: -h * 0.4)
            }
        }
    }
}

public struct BathMatIcon: View {
    public let color: Color

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.18, style: .continuous)
                    .fill(color.opacity(0.78))
                    .frame(width: w * 0.92, height: h * 0.62)
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: w * 0.1) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.46))
                                .frame(width: w * 0.08, height: w * 0.08)
                        }
                    }
                    .offset(y: (CGFloat(row) - 1) * h * 0.14)
                }
            }
        }
    }
}

public struct HangingTowelIcon: View {
    public let color: Color

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: w * 0.8, height: max(1.5, h * 0.1))
                RoundedRectangle(cornerRadius: w * 0.14, style: .continuous)
                    .fill(color.opacity(0.78))
                    .frame(width: w * 0.58, height: h * 0.78)
                    .offset(y: h * 0.1)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: h * 0.18))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.82))
                }
                .stroke(Color.white.opacity(0.38), lineWidth: max(1, w * 0.06))
            }
        }
    }
}

public struct WashclothIcon: View {
    public let color: Color

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                    .fill(color.opacity(0.78))
                    .frame(width: w * 0.78, height: h * 0.78)
                    .rotationEffect(.degrees(-5))
                RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: max(1, w * 0.06))
                    .frame(width: w * 0.52, height: h * 0.52)
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: w * 0.12, height: w * 0.12)
                    .offset(x: w * 0.22, y: -h * 0.22)
            }
        }
    }
}

public struct PillowCaseIcon: View {
    public let color: Color

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.2, style: .continuous)
                    .fill(color.opacity(0.74))
                    .frame(width: w * 0.9, height: h * 0.58)
                RoundedRectangle(cornerRadius: w * 0.14, style: .continuous)
                    .stroke(Color.white.opacity(0.54), lineWidth: max(1, w * 0.06))
                    .frame(width: w * 0.68, height: h * 0.38)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.28, y: h * 0.5))
                    path.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.38))
                }
                .stroke(Color.white.opacity(0.34), lineWidth: max(1, w * 0.045))
            }
        }
    }
}

public struct SheetStackIcon: View {
    public let color: Color

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
                        .fill(color.opacity(0.36 + Double(index) * 0.16))
                        .frame(width: w * 0.78, height: h * 0.24)
                        .offset(x: CGFloat(index) * w * 0.04, y: (CGFloat(index) - 1) * h * 0.2)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.38))
                                .frame(width: w * 0.34, height: max(1, h * 0.035))
                                .padding(.leading, w * 0.12)
                        }
                }
            }
        }
    }
}

public struct CoverIcon: View {
    public let color: Color

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                    .fill(color.opacity(0.78))
                    .frame(width: w * 0.86, height: h * 0.72)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.12, y: h * 0.38))
                    path.addCurve(
                        to: CGPoint(x: w * 0.88, y: h * 0.36),
                        control1: CGPoint(x: w * 0.34, y: h * 0.18),
                        control2: CGPoint(x: w * 0.62, y: h * 0.56)
                    )
                    path.move(to: CGPoint(x: w * 0.2, y: h * 0.62))
                    path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.62))
                }
                .stroke(Color.white.opacity(0.44), lineWidth: max(1, w * 0.06))
            }
        }
    }
}
