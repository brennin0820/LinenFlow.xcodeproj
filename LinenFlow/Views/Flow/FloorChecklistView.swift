import SwiftUI

struct DeliveryChecklistItemPar: Identifiable, Hashable {
    let itemName: String
    let availableAmount: Int
    let parAmount: Int
    let unit: String

    var id: String { itemName }
    var isParMet: Bool { availableAmount >= parAmount }
}

struct FloorChecklistView: View {
    let floorNumbers: [Int]
    let completedFloorNumbers: Set<Int>
    var bundlesPerFloor: [Int: Int] = [:]
    var itemParsByFloor: [Int: [DeliveryChecklistItemPar]] = [:]
    let onToggleFloor: (Int) -> Void
    var onResetCurrentPhase: () -> Void = {}
    let onReset: () -> Void
    @State private var deliveredItemParsByFloor: [Int: [DeliveryChecklistItemPar]] = [:]
    @State private var currentPhaseSignature: String = ""
    @State private var showTopFloorFirst = true
    @State private var showResetConfirmation = false

    private var deliveredCount: Int {
        displayFloorNumbers.filter { completedFloorNumbers.contains($0) }.count
    }

    private var remainingCount: Int {
        max(floorNumbers.count - deliveredCount, 0)
    }

    private var progress: Double {
        guard !displayFloorNumbers.isEmpty else { return 0 }
        return Double(deliveredCount) / Double(displayFloorNumbers.count)
    }

    private var displayFloorNumbers: [Int] {
        showTopFloorFirst ? Array(floorNumbers.reversed()) : floorNumbers
    }

    private var currentPhaseItemNames: [String] {
        let names = itemParsByFloor.values.flatMap { rows in
            rows.map(\.itemName)
        }
        return Array(Set(names)).sorted {
            LinenIconLibrary.itemComesBefore($0, $1)
        }
    }

    private var phaseSignature: String {
        currentPhaseItemNames.joined(separator: "|")
    }

    var body: some View {
        PremiumCard(accentColor: .green) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.10), lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int((progress * 100).rounded()))")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delivery Checklist")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text("\(remainingCount) floors left · \(currentPhaseItemNames.count)-item phase")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Button {
                            showTopFloorFirst.toggle()
                        } label: {
                            Image(systemName: showTopFloorFirst ? "arrow.down" : "arrow.up")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.82))
                                .frame(width: 30, height: 30)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showTopFloorFirst ? "Show bottom floor first" : "Show top floor first")

                        Button("Reset") {
                            showResetConfirmation = true
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))
                        .buttonStyle(.plain)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(displayFloorNumbers, id: \.self) { floor in
                        floorCard(for: floor)
                    }
                }
            }
        }
        .transaction { transaction in
            transaction.animation = nil
        }
        .onAppear {
            currentPhaseSignature = phaseSignature
            syncCompletions()
        }
        .onChange(of: floorNumbers) { _, _ in syncCompletions() }
        .onChange(of: completedFloorNumbers) { _, _ in syncCompletions() }
        .onChange(of: phaseSignature) { _, newValue in
            guard currentPhaseSignature != newValue else { return }
            currentPhaseSignature = newValue
            onResetCurrentPhase()
        }
        .confirmationDialog("Reset delivery checklist?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset Checklist", role: .destructive) {
                deliveredItemParsByFloor = [:]
                onReset()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This clears completed floor marks for this checklist. Saved daily logs are not deleted.")
        }
    }

    private func floorCard(for floor: Int) -> some View {
        let completion = completion(for: floor)
        let phaseIndex = (displayFloorNumbers.firstIndex(of: floor) ?? 0) + 1
        let totalPhases = displayFloorNumbers.count
        let floorBundles = bundlesPerFloor[floor] ?? 0
        let itemPars = displayedItemPars(for: floor)
        return Button {
            advanceStatus(for: floor)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: iconName(for: completion.status))
                            .font(.subheadline.weight(.bold))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.08), in: Circle())
                        Text("\(floor)")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .frame(minWidth: 38, alignment: .leading)
                    }
                    .layoutPriority(2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Floor \(phaseIndex)/\(totalPhases)")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(floorBundles > 0 ? "\(floorBundles) bdl this floor" : "\(remainingBundlesToDeliver) bdl left")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.52))
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text(label(for: completion.status))
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.075), in: Capsule())
                        .layoutPriority(1)
                }

                if !itemPars.isEmpty {
                    itemIndicatorStrip(itemPars)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: itemPars.isEmpty ? 64 : 96)
            .padding(.horizontal, 12)
            .padding(.vertical, itemPars.isEmpty ? 8 : 10)
            .background(fill(for: completion.status), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(stroke(for: completion.status), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delivered") { setStatus(.delivered, for: floor) }
            Button("Pending") { setStatus(.pending, for: floor) }
        }
        .accessibilityLabel("Floor \(floor), phase \(phaseIndex) of \(totalPhases)\(floorBundles > 0 ? ", \(floorBundles) bundles" : ""), \(itemParsAccessibilityLabel(itemPars)), \(label(for: completion.status))")
    }

    private func displayedItemPars(for floor: Int) -> [DeliveryChecklistItemPar] {
        let deliveredPars = deliveredItemParsByFloor[floor] ?? []
        if completedFloorNumbers.contains(floor) {
            return deliveredPars
        }
        return mergedItemPars(deliveredPars + (itemParsByFloor[floor] ?? []))
    }

    private func itemIndicatorStrip(_ itemPars: [DeliveryChecklistItemPar]) -> some View {
        LazyVGrid(columns: itemIndicatorColumns, alignment: .leading, spacing: 4) {
            ForEach(orderedItemPars(itemPars)) { itemPar in
                itemInitialIndicator(itemPar)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var itemIndicatorColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 34, maximum: 38), spacing: 5, alignment: .leading)]
    }

    private func itemInitialIndicator(_ itemPar: DeliveryChecklistItemPar) -> some View {
        let accent = LinenIconLibrary.color(forItem: itemPar.itemName)

        return ZStack {
            Text(initials(for: itemPar.itemName))
                .font(.title3.weight(.black).monospaced())
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 34, height: 32)

            if !itemPar.isParMet {
                Cross()
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 24, height: 24)
            }
        }
        .frame(width: 36, height: 34)
        .accessibilityLabel("\(itemPar.itemName), \(itemPar.availableAmount) of \(itemPar.parAmount) \(itemPar.unit)")
    }

    private func orderedItemPars(_ itemPars: [DeliveryChecklistItemPar]) -> [DeliveryChecklistItemPar] {
        mergedItemPars(itemPars).sorted {
            LinenIconLibrary.itemComesBefore($0.itemName, $1.itemName)
        }
    }

    private func mergedItemPars(_ itemPars: [DeliveryChecklistItemPar]) -> [DeliveryChecklistItemPar] {
        var merged: [String: DeliveryChecklistItemPar] = [:]
        for itemPar in itemPars {
            merged[itemPar.itemName] = itemPar
        }
        return Array(merged.values)
    }

    private func initials(for itemName: String) -> String {
        let words = itemName
            .split(separator: " ")
            .map(String.init)
        let initials = words.compactMap { $0.first }.map(String.init).joined()
        if initials.count >= 2 {
            return String(initials.prefix(2)).uppercased()
        }
        return String(itemName.prefix(2)).uppercased()
    }

    private var remainingBundlesToDeliver: Int {
        floorNumbers.reduce(0) { acc, floor in
            if completedFloorNumbers.contains(floor) {
                return acc
            }
            return acc + (bundlesPerFloor[floor] ?? 0)
        }
    }

    private func completion(for floor: Int) -> FloorCompletion {
        if completedFloorNumbers.contains(floor) {
            return FloorCompletion(floorNumber: floor, status: .delivered, completedAt: nil)
        }
        return FloorCompletion(floorNumber: floor)
    }

    private func advanceStatus(for floor: Int) {
        let current = completion(for: floor).status
        switch current {
        case .pending: setStatus(.delivered, for: floor)
        case .delivered: setStatus(.pending, for: floor)
        case .skipped: setStatus(.pending, for: floor)
        }
    }

    private func setStatus(_ status: FloorCompletion.Status, for floor: Int) {
        switch status {
        case .pending:
            removeCurrentPhaseItems(from: floor)
            if completedFloorNumbers.contains(floor) {
                onToggleFloor(floor)
            }
        case .delivered:
            snapshotDeliveredItemPars(for: floor)
            if !completedFloorNumbers.contains(floor) {
                onToggleFloor(floor)
            }
        case .skipped:
            removeCurrentPhaseItems(from: floor)
            if completedFloorNumbers.contains(floor) {
                onToggleFloor(floor)
            }
        }
    }

    private func syncCompletions() {
        deliveredItemParsByFloor = deliveredItemParsByFloor.filter { floor, _ in
            floorNumbers.contains(floor)
        }
        for floor in completedFloorNumbers.intersection(Set(floorNumbers)) {
            if deliveredItemParsByFloor[floor] == nil {
                snapshotDeliveredItemPars(for: floor)
            }
        }
    }

    private func snapshotDeliveredItemPars(for floor: Int) {
        deliveredItemParsByFloor[floor] = mergedItemPars((deliveredItemParsByFloor[floor] ?? []) + (itemParsByFloor[floor] ?? []))
    }

    private func removeCurrentPhaseItems(from floor: Int) {
        let currentNames = Set((itemParsByFloor[floor] ?? []).map(\.itemName))
        guard !currentNames.isEmpty else { return }
        let remaining = (deliveredItemParsByFloor[floor] ?? []).filter { !currentNames.contains($0.itemName) }
        if remaining.isEmpty {
            deliveredItemParsByFloor.removeValue(forKey: floor)
        } else {
            deliveredItemParsByFloor[floor] = remaining
        }
    }

    private func iconName(for status: FloorCompletion.Status) -> String {
        switch status {
        case .pending: return "circle"
        case .delivered: return "checkmark.circle.fill"
        case .skipped: return "circle"
        }
    }

    private func label(for status: FloorCompletion.Status) -> String {
        switch status {
        case .pending: return "Pending"
        case .delivered: return "Done"
        case .skipped: return "Pending"
        }
    }

    private func fill(for status: FloorCompletion.Status) -> Color {
        switch status {
        case .pending: return Color.white.opacity(0.055)
        case .delivered: return Color.green.opacity(0.26)
        case .skipped: return Color.white.opacity(0.055)
        }
    }

    private func stroke(for status: FloorCompletion.Status) -> Color {
        switch status {
        case .pending: return Color.white.opacity(0.08)
        case .delivered: return Color.green.opacity(0.44)
        case .skipped: return Color.white.opacity(0.08)
        }
    }

    private func itemParsAccessibilityLabel(_ itemPars: [DeliveryChecklistItemPar]) -> String {
        guard !itemPars.isEmpty else { return "no selected item par" }
        return itemPars
            .map { "\($0.itemName) \($0.availableAmount) of \($0.parAmount) \($0.unit)" }
            .joined(separator: ", ")
    }
}
private struct Cross: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 4, y: rect.minY + 4))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.maxY - 4))
        path.move(to: CGPoint(x: rect.maxX - 4, y: rect.minY + 4))
        path.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY - 4))
        return path
    }
}
