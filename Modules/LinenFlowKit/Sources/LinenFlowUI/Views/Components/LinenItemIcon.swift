import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public enum LinenIconCategory {
    case bathTowel
    case bathMat
    case handTowel
    case washcloth
    case pillowCase
    case sheet
    case cover
    case generic
}

public struct LinenItemIcon: View {
    public let itemName: String
    public var size: CGFloat
    public var boxed = false

    public var body: some View {
        let accent = LinenIconLibrary.color(forItem: itemName)
        ZStack {
            if boxed {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accent.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(accent.opacity(0.40), lineWidth: 1)
                    )
            }
            icon
                .frame(width: size * 0.78, height: size * 0.78)

            badge
                .offset(x: size * 0.28, y: size * 0.28)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var icon: some View {
        let linenColor = Color(red: 0.92, green: 0.97, blue: 1.0)
        switch category {
        case .bathTowel:
            FoldedTowelIcon(color: linenColor)
        case .bathMat:
            BathMatIcon(color: linenColor)
        case .handTowel:
            HangingTowelIcon(color: linenColor)
        case .washcloth:
            WashclothIcon(color: linenColor)
        case .pillowCase:
            PillowCaseIcon(color: linenColor)
        case .sheet:
            SheetStackIcon(color: linenColor)
        case .cover:
            CoverIcon(color: linenColor)
        case .generic:
            Image(systemName: "shippingbox.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var badge: some View {
        Text(badgeText)
            .font(.system(size: max(5, size * 0.2), weight: .black, design: .rounded))
            .minimumScaleFactor(0.55)
            .lineLimit(1)
            .foregroundStyle(.white)
            .frame(width: size * 0.44, height: size * 0.44)
            .background(
                Circle()
                    .fill(badgeColor)
                    .shadow(color: badgeColor.opacity(0.45), radius: 3, y: 1)
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.32), lineWidth: max(0.6, size * 0.025))
            )
    }

    public var category: LinenIconCategory {
        switch itemName {
        case "Bath Towel": return .bathTowel
        case "Bath Mat": return .bathMat
        case "Hand Towel": return .handTowel
        case "Washcloth": return .washcloth
        case "Pillow Case": return .pillowCase
        case "King Sheet", "Queen Sheet", "Double Sheet", "Twin Sheet": return .sheet
        case "King Cover", "Queen Cover", "Double Cover", "Twin Cover": return .cover
        default: return .generic
        }
    }

    private var badgeText: String {
        switch itemName {
        case "Bath Towel": return "BT"
        case "Bath Mat": return "BM"
        case "Hand Towel": return "HT"
        case "Washcloth": return "WC"
        case "Pillow Case": return "PC"
        case "King Sheet": return "KS"
        case "Queen Sheet": return "QS"
        case "Double Sheet": return "DS"
        case "Twin Sheet": return "TS"
        case "King Cover": return "KC"
        case "Queen Cover": return "QC"
        case "Double Cover": return "DC"
        case "Twin Cover": return "TC"
        default:
            return String(itemName.prefix(2)).uppercased()
        }
    }

    private var badgeColor: Color {
        LinenIconLibrary.color(forItem: itemName)
    }
}
