import CoreLocation
import SwiftUI

struct PropertyMapView: View {
    let towers: [Tower]

    @State private var isMapExpanded = false
    @State private var selectedTowerID: UUID?

    private var mappedTowers: [(tower: Tower, coordinate: CLLocationCoordinate2D)] {
        HiltonPropertyMap.mappedTowers(from: towers)
    }

    var body: some View {
        PremiumCard(accentColor: .cyan) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.cyan)
                        .frame(width: 30, height: 30)
                        .background(Color.cyan.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Property Overview")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Waikiki · Hilton Hawaiian Village")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    Spacer()

                    if !mappedTowers.isEmpty {
                        Text("\(mappedTowers.count) towers mapped")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.cyan.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cyan.opacity(0.12), in: Capsule())
                    }
                }

                if mappedTowers.isEmpty {
                    staticPropertyPreview
                } else if isMapExpanded {
                    expandedPropertyMap
                } else {
                    previewPropertyMap
                }

                Button {
                    UIApplication.shared.open(HiltonPropertyMap.appleMapsURL)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "map")
                        Text("Open in Apple Maps")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.cyan.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Hilton Hawaiian Village in Apple Maps")
            }
        }
    }

    private var staticPropertyPreview: some View {
        Image("property_overview")
            .resizable()
            .scaledToFill()
            .frame(height: 168)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Label("Rainbow Tower · Duke Lagoon · Kahanamoku Beach", systemImage: "binoculars.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(10)
            }
            .accessibilityLabel("Hilton Hawaiian Village satellite map")
    }

    private var previewPropertyMap: some View {
        PropertySceneMapView(
            mappedTowers: mappedTowers,
            focusTowerID: selectedTowerID,
            selectedTowerID: selectedTowerID,
            isExpanded: false,
            isInteractive: false,
            shouldOrbit: true,
            onTowerSelected: nil
        )
        .frame(height: 168)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            Label("Tap to explore in 3D", systemImage: "cube.transparent.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(10)
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(8)
                .background(.black.opacity(0.42), in: Circle())
                .padding(10)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.snappy(duration: 0.2)) {
                isMapExpanded = true
            }
        }
        .accessibilityLabel("Hilton Hawaiian Village 3D property map")
        .accessibilityHint("Double tap to expand interactive tower map")
    }

    private var expandedPropertyMap: some View {
        PropertySceneMapView(
            mappedTowers: mappedTowers,
            focusTowerID: selectedTowerID,
            selectedTowerID: selectedTowerID,
            isExpanded: true,
            isInteractive: true,
            shouldOrbit: selectedTowerID == nil,
            onTowerSelected: { tower in
                selectedTowerID = tower.id
            }
        )
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    isMapExpanded = false
                    selectedTowerID = nil
                }
            } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.52), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
