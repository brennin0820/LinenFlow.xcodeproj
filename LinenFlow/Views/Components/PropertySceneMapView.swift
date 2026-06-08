import CoreLocation
import MapKit
import SwiftUI

struct PropertySceneMapView: View {
    let mappedTowers: [(tower: Tower, coordinate: CLLocationCoordinate2D)]
    var focusTowerID: UUID?
    var selectedTowerID: UUID?
    var isExpanded: Bool = true
    var isInteractive: Bool = true
    var shouldOrbit: Bool = false
    var onTowerSelected: ((Tower) -> Void)? = nil

    @State private var cameraPosition: MapCameraPosition = .camera(HiltonPropertyMap.overviewCamera())
    @State private var orbitStart = Date.now

    private var focusCoordinate: CLLocationCoordinate2D? {
        if let focusTowerID,
           let entry = mappedTowers.first(where: { $0.tower.id == focusTowerID }) {
            return entry.coordinate
        }
        return nil
    }

    var body: some View {
        Group {
            if mappedTowers.isEmpty {
                fallbackImagery
            } else if shouldOrbit && focusCoordinate == nil {
                TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                    propertyMap
                        .onChange(of: timeline.date) { _, date in
                            applyOrbitCamera(at: date)
                        }
                }
            } else {
                propertyMap
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            syncCamera(animated: false)
        }
        .onChange(of: focusTowerID) { _, _ in
            syncCamera(animated: true)
        }
        .onChange(of: selectedTowerID) { _, _ in
            syncCamera(animated: true)
        }
        .onChange(of: isExpanded) { _, _ in
            syncCamera(animated: true)
        }
        .onChange(of: shouldOrbit) { _, orbiting in
            if orbiting {
                orbitStart = .now
            }
            syncCamera(animated: true)
        }
    }

    private var propertyMap: some View {
        Map(position: $cameraPosition, interactionModes: isInteractive ? .all : []) {
            ForEach(mappedTowers, id: \.tower.id) { entry in
                Annotation(entry.tower.name, coordinate: entry.coordinate, anchor: .bottom) {
                    towerMarker(for: entry.tower)
                }
            }
        }
        .mapStyle(HiltonPropertyMap.style3D)
        .allowsHitTesting(isInteractive)
    }

    @ViewBuilder
    private func towerMarker(for tower: Tower) -> some View {
        let isFocused = tower.id == focusTowerID || tower.id == selectedTowerID
        if isInteractive, let onTowerSelected {
            Button {
                onTowerSelected(tower)
            } label: {
                TowerMapMarker(
                    name: tower.name,
                    colorHex: tower.identityColorHex,
                    isFocused: isFocused
                )
            }
            .buttonStyle(.plain)
        } else {
            TowerMapMarker(
                name: tower.name,
                colorHex: tower.identityColorHex,
                isFocused: isFocused
            )
        }
    }

    private var fallbackImagery: some View {
        Image("property_overview")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    private func syncCamera(animated: Bool) {
        guard focusCoordinate != nil || !shouldOrbit else {
            applyOrbitCamera(at: .now)
            return
        }

        let camera = camera(for: .now)
        if animated {
            withAnimation(.easeInOut(duration: 0.45)) {
                cameraPosition = .camera(camera)
            }
        } else {
            cameraPosition = .camera(camera)
        }
    }

    private func applyOrbitCamera(at date: Date) {
        guard shouldOrbit, focusCoordinate == nil else { return }
        cameraPosition = .camera(camera(for: date))
    }

    private func camera(for date: Date) -> MapCamera {
        if let coordinate = focusCoordinate {
            return MapCamera(
                centerCoordinate: coordinate,
                distance: isExpanded ? 380 : 520,
                heading: 18,
                pitch: isExpanded ? 72 : 58
            )
        }

        if shouldOrbit {
            return MapCamera(
                centerCoordinate: HiltonPropertyMap.center,
                distance: isExpanded ? 880 : 1_050,
                heading: HiltonPropertyMap.orbitHeading(at: date, start: orbitStart),
                pitch: HiltonPropertyMap.orbitPitch(at: date, start: orbitStart)
            )
        }

        return HiltonPropertyMap.overviewCamera(
            heading: 24,
            pitch: isExpanded ? 62 : 50
        )
    }
}
