import CoreLocation
import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct TowerPickerEnvironmentView: View {
    public let towers: [Tower]
    public let selectedTower: Tower?
    public let focusTowerID: UUID?
    public var isExpanded: Bool
    public var hint: String? = nil

    private var mappedTowers: [(tower: Tower, coordinate: CLLocationCoordinate2D)] {
        HiltonPropertyMap.mappedTowers(from: towers)
    }

    private var focusTower: Tower? {
        if let focusTowerID {
            return towers.first { $0.id == focusTowerID }
        }
        return selectedTower
    }

    private var mapHeight: CGFloat {
        isExpanded ? 118 : 96
    }

    private var shouldOrbit: Bool {
        isExpanded && focusTower == nil && !mappedTowers.isEmpty
    }

    public var body: some View {
        Group {
            if mappedTowers.isEmpty {
                fallbackImagery
            } else {
                PropertySceneMapView(
                    mappedTowers: mappedTowers,
                    focusTowerID: focusTower?.id,
                    selectedTowerID: selectedTower?.id,
                    isExpanded: isExpanded,
                    isInteractive: isExpanded,
                    shouldOrbit: shouldOrbit,
                    onTowerSelected: nil
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: mapHeight)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            environmentBadge
        }
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, .black.opacity(0.42)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 44)
            .allowsHitTesting(false)
        }
        .animation(.easeInOut(duration: 0.45), value: mapHeight)
    }

    private var fallbackImagery: some View {
        Image("property_overview")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .scaleEffect(1.04)
            .offset(x: 4, y: 2)
    }

    private var environmentBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
                .shadow(color: .green.opacity(0.8), radius: 4)
            Text(focusTower?.name ?? "Waikiki Map")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
            if let hint, focusTower == nil {
                Text("·")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(hint)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.black.opacity(0.48), in: Capsule())
        .padding(8)
    }
}
