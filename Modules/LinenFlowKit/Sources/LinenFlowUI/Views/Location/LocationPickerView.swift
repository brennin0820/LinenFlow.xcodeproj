import CoreLocation
import MapKit
import SwiftData
import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct LocationPickerView: View {
    public let title: String
    public let locationType: SavedLocation.LocationType
    public var existing: SavedLocation?
    public var onSave: (SavedLocation) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var label: String
    @State private var coordinate: CLLocationCoordinate2D
    @State private var radiusMeters: Double
    @State private var cameraPosition: MapCameraPosition

    public init(
        title: String,
        locationType: SavedLocation.LocationType,
        existing: SavedLocation? = nil,
        onSave: @escaping (SavedLocation) async -> Void
    ) {
        self.title = title
        self.locationType = locationType
        self.existing = existing
        self.onSave = onSave

        let initialCoordinate = existing?.coordinate ?? CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        _label = State(initialValue: existing?.label ?? title)
        _coordinate = State(initialValue: initialCoordinate)
        _radiusMeters = State(initialValue: existing?.radiusMeters ?? 200)
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoordinate,
            latitudinalMeters: 1200,
            longitudinalMeters: 1200
        )))
    }

    public var body: some View {
        VStack(spacing: 0) {
            mapSection
            controlsSection
        }
        .background(HimmerFlowColors.background)
        .navigationTitle("\(title) Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveLocation() }
                    .fontWeight(.semibold)
            }
        }
    }

    private var mapSection: some View {
        MapReader { reader in
            Map(position: $cameraPosition, interactionModes: .all) {
                Marker(label, coordinate: coordinate)
                MapCircle(center: coordinate, radius: radiusMeters)
                    .foregroundStyle(HimmerFlowColors.accent.opacity(0.20))
                    .stroke(HimmerFlowColors.accent, lineWidth: 2)
            }
            .mapStyle(.standard(elevation: .flat))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        if let point = reader.convert(value.location, from: .local) {
                            coordinate = point
                        }
                    }
            )
        }
        .frame(height: 320)
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Label")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HimmerFlowColors.mutedText)
                TextField("Location name", text: $label)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Detection radius")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HimmerFlowColors.mutedText)
                    Spacer()
                    Text("\(Int(radiusMeters)) m")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(HimmerFlowColors.accent)
                }
                Slider(value: $radiusMeters, in: 100...500, step: 25)
                    .tint(HimmerFlowColors.accent)
                Text("Tap the map to move the pin. Wider radius is more forgiving but less precise.")
                    .font(.caption2)
                    .foregroundStyle(HimmerFlowColors.mutedText)
            }

            Text("Lat \(coordinate.latitude, format: .number.precision(.fractionLength(4))) · Lon \(coordinate.longitude, format: .number.precision(.fractionLength(4)))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(HimmerFlowColors.mutedText)
        }
        .padding(16)
    }

    private func saveLocation() {
        let location: SavedLocation
        if let existing {
            existing.label = label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? title : label
            existing.latitude = coordinate.latitude
            existing.longitude = coordinate.longitude
            existing.radiusMeters = radiusMeters
            existing.locationType = locationType
            location = existing
        } else {
            location = SavedLocation(
                label: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? title : label,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radiusMeters: radiusMeters,
                locationType: locationType
            )
            modelContext.insert(location)
        }

        try? modelContext.save()
        Task {
            await onSave(location)
            dismiss()
        }
    }
}
