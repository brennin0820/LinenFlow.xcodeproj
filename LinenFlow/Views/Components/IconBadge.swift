import SwiftUI

struct IconBadge: View {
    let systemName: String
    let backgroundColor: Color
    let foregroundColor: Color
    let size: CGFloat
    let cornerRadius: CGFloat

    init(
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

    var body: some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
