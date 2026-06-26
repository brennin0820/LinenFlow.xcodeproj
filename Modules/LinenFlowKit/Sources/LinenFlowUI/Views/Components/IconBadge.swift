import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct IconBadge: View {
    public let systemName: String
    public let backgroundColor: Color
    public let foregroundColor: Color
    public let size: CGFloat
    public let cornerRadius: CGFloat

    public init(
        systemName: String,
        backgroundColor: Color,
        foregroundColor: Color = .white,
        size: CGFloat = 32,
        cornerRadius: CGFloat = 8
    ) {
        self.systemName = systemName
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.size = size
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
