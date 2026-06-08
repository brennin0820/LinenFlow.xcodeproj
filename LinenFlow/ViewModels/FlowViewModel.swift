import Foundation
import SwiftData
import Observation
import WidgetKit
import OSLog

struct TowerDisplayGroupSection: Identifiable {
    let group: TowerDisplayGroup
    let towers: [Tower]

    var id: TowerDisplayGroup { group }
}

struct LinenItemDisplayGroupSection: Identifiable {
    let group: LinenItemDisplayGroup
    let items: [LinenItem]

    var id: LinenItemDisplayGroup { group }
}

struct TowerParRequirement: Identifiable, Hashable {
    let id: UUID
    let itemName: String
    let floorCount: Int
    let parPerFloor: Int
    let bundleSize: Int
    let requiredPieces: Int
    let requiredBundles: Int
    let receivedPieces: Int
    let receivedFullBundles: Int
    let summaryDifferencePieces: Int?
    let summaryDifferenceBundles: Int?

    var receivedBundles: Int {
        receivedFullBundles
    }

    var pieceGap: Int {
        summaryDifferencePieces ?? (receivedPieces - requiredPieces)
    }

    var bundleGap: Int {
        summaryDifferenceBundles ?? (receivedBundles - requiredBundles)
    }
}

struct FloorDeliveryAmount: Identifiable, Hashable {
    let id: String
    let floorNumber: Int
    let itemName: String
    let amount: Int
    let unit: String

    var amountText: String {
        "\(amount) \(unit)"
    }
}

@Observable
@MainActor
final class FlowViewModel {
    let modelContext: ModelContext

    var selectedTower: Tower?
    private(set) var availableTowers: [Tower] = []
    private(set) var availableItems: [LinenItem] = []
    private(set) var receivingEntries: [ReceivingEntry] = []
    private(set) var calculationSummaries: [CalculationSummary] = []
    private(set) var floorDistributions: [FloorDistributionRow] = []
    private(set) var bundleFloorDistributions: [FloorDistributionRow] = []
    var notes: String = ""
    private(set) var validationWarnings: [String] = []
    private(set) var supplyPredictions: [ItemSupplyPrediction] = []
    private(set) var supplyAnomalies: [SupplyAnomaly] = []
    private let shiftIntelligence = ShiftIntelligenceService()
    private(set) var isDemoDay: Bool = false
    private(set) var saveError: String?
    private(set) var currentDeliveryItemName: String?
    private(set) var deliverySessionState = DeliverySessionState()
    private var widgetShiftSettings: ShiftSettings?
    private var lastCompletedFloorNumber: Int?

    // SmartTips
    private let smartTipsService = SmartTipsService()
    private(set) var activeSmartTip: SmartTip?
    private var lastAutoPresented: Set<SmartTipID> = []

    // Current Trip (carry plan for this elevator trip)
    static let currentTripMaxItems = 2
    private(set) var currentTripItemNamesSet: [String] = []

    private static let lastTowerIDKey = "himmerflow.lastSelectedTowerID"
    private static let pinnedWidgetItemsKey = "himmerflow.pinnedWidgetItemNames"
    private static let currentTripItemsKey = "himmerflow.currentTripItemNames"
    private static let widgetKind = "HimmerFlow_Widget"
    private static let legacyUserDefaultsMigrationKey = "himmerflow.migratedUserDefaultsFromLinenFlow"
    private static let legacyUserDefaultsKeyMappings: [(legacy: String, current: String)] = [
        ("linenflow.lastSelectedTowerID", lastTowerIDKey),
        ("linenflow.pinnedWidgetItemNames", pinnedWidgetItemsKey),
        ("linenflow.currentTripItemNames", currentTripItemsKey),
    ]

    private static let pendingLiveActivityDropsKey = "pendingLiveActivityDrops"
    private static let pendingLiveActivityDropFloorsKey = "pendingLiveActivityDropFloors"
    private static let pendingLiveActivityUndoFloorsKey = "pendingLiveActivityUndoFloors"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Self.migrateLegacyUserDefaultsKeys()
        refreshAvailable()
        restoreLastSelectedTower()
        restoreCurrentTripItems()
        restoreDeliverySessionFromSharedWidgetStateIfNeeded()
    }

    func configureWidgetShiftSettings(_ shiftSettings: ShiftSettings) {
        widgetShiftSettings = shiftSettings
    }

    // MARK: - Widget item pinning

    var pinnedWidgetItemNames: [String] {
        get {
            let raw = UserDefaults.standard.string(forKey: Self.pinnedWidgetItemsKey) ?? ""
            return raw.isEmpty ? [] : raw.split(separator: ",").map(String.init)
        }
        set {
            UserDefaults.standard.set(newValue.prefix(3).joined(separator: ","), forKey: Self.pinnedWidgetItemsKey)
        }
    }

    func isWidgetPinned(_ itemName: String) -> Bool {
        pinnedWidgetItemNames.contains(itemName)
    }

    func toggleWidgetPin(for itemName: String) {
        var pinned = pinnedWidgetItemNames
        if let idx = pinned.firstIndex(of: itemName) {
            pinned.remove(at: idx)
        } else if pinned.count < 3 {
            pinned.append(itemName)
        }
        pinnedWidgetItemNames = pinned
        syncWidgetState()
    }

    // MARK: - Tower management

    func refreshAvailable() {
        var towerDescriptor = FetchDescriptor<Tower>(predicate: #Predicate { $0.isActive })
        towerDescriptor.sortBy = [SortDescriptor(\.name)]
        availableTowers = (try? modelContext.fetch(towerDescriptor)) ?? []

        var itemDescriptor = FetchDescriptor<LinenItem>(predicate: #Predicate { $0.isActive })
        itemDescriptor.sortBy = [SortDescriptor(\.name)]
        availableItems = (try? modelContext.fetch(itemDescriptor)) ?? []

        // Auto-deselect if selected tower was deactivated
        if let selected = selectedTower, !availableTowers.contains(where: { $0.id == selected.id }) {
            selectedTower = nil
            UserDefaults.standard.removeObject(forKey: Self.lastTowerIDKey)
            recalculate()
        }
    }

    func selectTower(_ tower: Tower) {
        let towerChanged = selectedTower?.id != tower.id
        if deliverySessionState.isActive, towerChanged {
            AppLogger.session.warning("Tower changed while delivery active — resetting session (was: \(self.deliverySessionState.towerName, privacy: .public))")
            resetDeliverySessionAndEndActivity()
        }
        if towerChanged {
            // A new tower means a new shift plan — yesterday's trip selection is meaningless.
            currentTripItemNamesSet.removeAll()
            persistCurrentTripItems()
        }
        selectedTower = tower
        UserDefaults.standard.set(tower.id.uuidString, forKey: Self.lastTowerIDKey)
        recalculate()
    }

    func updateSelectedTowerFloorCount(_ floorCount: Int) {
        guard let selectedTower else { return }
        if let protectedCount = TowerOperationalPolicy.confirmedDeliveryFloorCount(for: selectedTower) {
            if selectedTower.floorCount != protectedCount {
                selectedTower.floorCount = protectedCount
                selectedTower.updatedAt = .now
                try? modelContext.save()
                recalculate()
            }
            return
        }
        selectedTower.floorCount = min(max(floorCount, 1), 80)
        selectedTower.updatedAt = .now
        do {
            try modelContext.save()
        } catch {
            saveError = "Could not save floor count: \(error.localizedDescription)"
        }
        recalculate()
    }

    func selectedItemIDs(for tower: Tower) -> Set<UUID> {
        Set(availableItems.filter { itemIsAvailable($0, for: tower) }.map(\.id))
    }

    func itemIsAvailable(_ item: LinenItem, for tower: Tower) -> Bool {
        switch item.availabilityScope {
        case .allTowers:
            return true
        case .selectedTowers:
            return item.allowedTowerNames.contains(tower.name)
        }
    }

    var towerDisplayGroups: [TowerDisplayGroupSection] {
        TowerDisplayGroup.allCases.compactMap { group in
            let towers = availableTowers
                .filter { $0.displayGroup == group }
                .sorted { $0.name < $1.name }
            return towers.isEmpty ? nil : TowerDisplayGroupSection(group: group, towers: towers)
        }
    }

    func itemDisplayGroups(for tower: Tower?) -> [LinenItemDisplayGroupSection] {
        let items = availableItems
            .filter { item in
                guard let tower else { return true }
                return itemIsAvailable(item, for: tower)
            }
        return LinenItemDisplayGroup.allCases.compactMap { group in
            let groupedItems = items
                .filter { $0.displayGroup == group }
                .sorted { $0.name < $1.name }
            return groupedItems.isEmpty ? nil : LinenItemDisplayGroupSection(group: group, items: groupedItems)
        }
    }

    var towerParRequirements: [TowerParRequirement] {
        guard let tower = selectedTower else { return [] }
        let floorCount = DeliveryFloorSequenceService.deliveryFloors(for: tower).count
        let summariesByName = Dictionary(uniqueKeysWithValues: calculationSummaries.map { ($0.itemName, $0) })

        return availableItems
            .filter { itemIsAvailable($0, for: tower) }
            .map { item in
                let bundleSize = max(item.bundleSize, 1)
                let parCountsBundles = tower.deliveryMode != .pieces
                let requiredBundles: Int
                let requiredPieces: Int
                if parCountsBundles {
                    requiredBundles = LinenCalculatorService.calculateRequiredBundles(
                        floorCount: floorCount,
                        parCount: max(0, item.parCount)
                    )
                    requiredPieces = requiredBundles * bundleSize
                } else {
                    requiredPieces = max(0, floorCount * item.parCount)
                    requiredBundles = LinenCalculatorService.calculateRequiredBundlesFromPieces(
                        requiredPieces: requiredPieces,
                        bundleSize: bundleSize
                    )
                }
                let summary = summariesByName[item.name]
                return TowerParRequirement(
                    id: item.id,
                    itemName: item.name,
                    floorCount: floorCount,
                    parPerFloor: max(0, item.parCount),
                    bundleSize: bundleSize,
                    requiredPieces: requiredPieces,
                    requiredBundles: requiredBundles,
                    receivedPieces: summary?.receivedPieces ?? 0,
                    receivedFullBundles: summary?.fullBundles ?? 0,
                    summaryDifferencePieces: summary?.differencePieces,
                    summaryDifferenceBundles: summary?.differenceBundles
                )
            }
            .sorted { lhs, rhs in
                if lhs.pieceGap < 0, rhs.pieceGap >= 0 { return true }
                if lhs.pieceGap >= 0, rhs.pieceGap < 0 { return false }
                return lhs.itemName < rhs.itemName
            }
    }

    func saveSelectedItems(_ selectedItemIDs: Set<UUID>, for tower: Tower) throws {
        let selectedItemNames = Set(availableItems.filter { selectedItemIDs.contains($0.id) }.map(\.name))

        for item in availableItems {
            switch item.availabilityScope {
            case .allTowers:
                if !selectedItemIDs.contains(item.id) {
                    // Explicitly deselecting an all-towers item — restrict it
                    let allTowerNames = availableTowers.map(\.name).filter { $0 != tower.name }
                    item.allowedTowerNames = allTowerNames.sorted()
                    item.availabilityScope = .selectedTowers
                    item.updatedAt = .now
                }
                // If selected and allTowers, leave as allTowers
            case .selectedTowers:
                var allowed = Set(item.allowedTowerNames)
                if selectedItemIDs.contains(item.id) {
                    allowed.insert(tower.name)
                } else {
                    allowed.remove(tower.name)
                }
                item.allowedTowerNames = allowed.sorted()
                item.updatedAt = .now
            }
        }

        receivingEntries.removeAll { !selectedItemNames.contains($0.itemName) }
        try modelContext.save()
        refreshAvailable()
        recalculate()
    }

    // MARK: - Receiving entries

    func addOrUpdateReceivingEntry(
        item: LinenItem,
        binCount: Int? = nil,
        manualPieces: Int? = nil,
        physicalBinCount: Int? = nil,
        notes: String? = nil
    ) {
        let entry = makeEntry(
            item: item,
            binCount: binCount,
            manualPieces: manualPieces,
            physicalBinCount: physicalBinCount,
            notes: notes
        )
        if let idx = receivingEntries.firstIndex(where: { $0.itemName == item.name }) {
            receivingEntries[idx] = entry
        } else {
            receivingEntries.append(entry)
        }
        recalculate()
    }

    /// One-screen calculator: user enters received pieces directly.
    func addOrUpdateReceivedPieces(item: LinenItem, pieces: Int) {
        receivingEntries.removeAll { $0.itemName == item.name }

        guard pieces > 0 else {
            if currentDeliveryItemName == item.name {
                currentDeliveryItemName = nil
            }
            recalculate()
            return
        }

        let (full, loose) = LinenCalculatorService.convertPiecesToBundles(
            pieces: pieces,
            bundleSize: item.bundleSize
        )
        receivingEntries.append(ReceivingEntry(
            itemName: item.name,
            countMethod: .manualPieces,
            manualPieces: pieces,
            calculatedPieces: pieces,
            calculatedFullBundles: full,
            loosePieces: loose
        ))
        recalculate()
    }

    func addCartLabelRow(item: LinenItem, pieces: Int, cartNumber: String? = nil) {
        let note = cartNumber.map { "Cart \($0)" }
        let entry = ReceivingEntry(
            itemName: item.name,
            countMethod: .cartLabelPieces,
            binCount: nil,
            manualPieces: pieces,
            piecesPerBin: nil,
            calculatedPieces: pieces,
            calculatedFullBundles: 0,
            loosePieces: 0,
            notes: note
        )
        receivingEntries.append(entry)
        recalculate()
    }

    func removeReceivingEntry(_ entry: ReceivingEntry) {
        receivingEntries.removeAll { $0.id == entry.id }
        if currentDeliveryItemName == entry.itemName {
            currentDeliveryItemName = nil
        }
        recalculate()
    }

    func randomizeReceivingEntriesForTesting() {
        guard let tower = selectedTower else { return }
        let towerItems = availableItems.filter { itemIsAvailable($0, for: tower) }
        guard !towerItems.isEmpty else { return }

        let towerItemNames = Set(towerItems.map(\.name))
        receivingEntries.removeAll { towerItemNames.contains($0.itemName) }

        let floorCount = max(DeliveryFloorSequenceService.deliveryFloors(for: tower).count, 1)
        for item in towerItems {
            let bundleSize = max(item.bundleSize, 1)
            let baseRequiredPieces = usesParSystem
                ? max(floorCount * max(item.parCount, 1), bundleSize)
                : max(floorCount * bundleSize, bundleSize)
            let multiplier = Double.random(in: 0.75...1.35)

            switch item.countMethod {
            case .fixedBin:
                let piecesPerBin = max(item.piecesPerBin ?? bundleSize, 1)
                let targetBins = max(1, Int((Double(baseRequiredPieces) * multiplier / Double(piecesPerBin)).rounded()))
                receivingEntries.append(makeEntry(
                    item: item,
                    binCount: targetBins,
                    manualPieces: nil,
                    physicalBinCount: targetBins,
                    notes: "Random test count"
                ))
            case .manualPieces, .cartLabelPieces:
                let targetPieces = max(bundleSize, Int((Double(baseRequiredPieces) * multiplier).rounded()))
                receivingEntries.append(makeEntry(
                    item: item,
                    binCount: nil,
                    manualPieces: targetPieces,
                    physicalBinCount: nil,
                    notes: "Random test count"
                ))
            }
        }

        recalculate()
    }

    func selectCurrentDeliveryItem(_ itemName: String?) {
        setCurrentDeliveryItem(itemName)
    }

    // MARK: - Delivery session

    func startDeliverySession() {
        guard let tower = selectedTower else { return }
        guard !deliverySessionState.isActive else {
            AppLogger.session.warning("startDeliverySession called while already active — ignoring")
            return
        }
        let floors = DeliveryFloorSequenceService.deliveryFloors(for: tower)
        AppLogger.session.info("Starting delivery session: \(tower.name, privacy: .public), \(floors.count) floors")
        deliverySessionState = DeliverySessionState(
            isActive: true,
            isPaused: false,
            towerName: tower.name,
            floorCount: floors.count,
            deliveryFloors: floors,
            completedFloorNumbers: [],
            currentItemName: currentDeliveryItemName,
            nextCarryGroupTitle: deliverySessionState.nextCarryGroupTitle ?? carryGroups.first?.label,
            startedAt: .now,
            pausedAt: nil,
            finishedAt: nil
        )
        currentDeliveryItemName = deliverySessionState.currentItemName
        syncDeliverySessionState(startActivity: true)
    }

    func pauseDeliverySession() {
        guard deliverySessionState.isActive, !deliverySessionState.isPaused else { return }
        AppLogger.session.info("Delivery paused at \(self.deliverySessionState.completedCount)/\(self.deliverySessionState.floorCount) floors")
        deliverySessionState.isPaused = true
        deliverySessionState.pausedAt = .now
        syncDeliverySessionState()
    }

    func resumeDeliverySession() {
        guard deliverySessionState.isActive, deliverySessionState.isPaused else { return }
        AppLogger.session.info("Delivery resumed at \(self.deliverySessionState.completedCount)/\(self.deliverySessionState.floorCount) floors")
        deliverySessionState.isPaused = false
        deliverySessionState.pausedAt = nil
        syncDeliverySessionState(startActivity: true)
    }

    func finishDeliverySession() {
        guard deliverySessionState.isActive else { return }
        AppLogger.session.info("Delivery finished: \(self.deliverySessionState.completedCount)/\(self.deliverySessionState.floorCount) floors complete")
        deliverySessionState.isActive = false
        deliverySessionState.isPaused = false
        deliverySessionState.finishedAt = .now
        syncDeliverySessionState(endActivity: true)
    }

    func markFloorComplete(_ floorNumber: Int) {
        ensureDeliverySessionPrepared()
        guard deliverySessionState.deliveryFloors.contains(floorNumber) else { return }
        deliverySessionState.completedFloorNumbers.insert(floorNumber)
        lastCompletedFloorNumber = floorNumber
        if deliverySessionState.isComplete {
            deliverySessionState.finishedAt = deliverySessionState.finishedAt ?? .now
        }
        syncDeliverySessionState()
    }

    func unmarkFloorComplete(_ floorNumber: Int) {
        ensureDeliverySessionPrepared()
        deliverySessionState.completedFloorNumbers.remove(floorNumber)
        if lastCompletedFloorNumber == floorNumber {
            lastCompletedFloorNumber = nil
        }
        if !deliverySessionState.isComplete {
            deliverySessionState.finishedAt = nil
        }
        syncDeliverySessionState()
    }

    func toggleFloorComplete(_ floorNumber: Int) {
        if deliverySessionState.completedFloorNumbers.contains(floorNumber) {
            unmarkFloorComplete(floorNumber)
        } else {
            markFloorComplete(floorNumber)
        }
    }

    func setCurrentDeliveryItem(_ itemName: String?) {
        currentDeliveryItemName = itemName
        deliverySessionState.currentItemName = itemName
        syncDeliverySessionState()
    }

    // MARK: - SmartTips

    var smartTipsEnabled: Bool { smartTipsService.smartTipsEnabled }
    var autoOpenTipsEnabled: Bool { smartTipsService.autoOpenTipsEnabled }
    var showTipButtons: Bool { smartTipsService.showTipButtons }

    func setSmartTipsEnabled(_ enabled: Bool) {
        smartTipsService.smartTipsEnabled = enabled
        if !enabled { activeSmartTip = nil }
    }

    func setAutoOpenTipsEnabled(_ enabled: Bool) {
        smartTipsService.autoOpenTipsEnabled = enabled
    }

    func setShowTipButtons(_ enabled: Bool) {
        smartTipsService.showTipButtons = enabled
    }

    func dismissSmartTip(markDismissed: Bool) {
        if markDismissed, let tip = activeSmartTip {
            smartTipsService.markDismissed(tip.id)
        }
        activeSmartTip = nil
    }

    func turnOffSmartTips() {
        activeSmartTip = nil
        smartTipsService.smartTipsEnabled = false
    }

    func presentSmartTip(_ tipID: SmartTipID, force: Bool = false) {
        guard smartTipsService.canPresentManually(tipID, smartTipsEnabled: smartTipsService.smartTipsEnabled, force: force) else { return }
        activeSmartTip = smartTipsService.smartTip(for: tipID)
    }

    func autoPresentSmartTip(_ tipID: SmartTipID) {
        guard activeSmartTip == nil else { return }
        guard !lastAutoPresented.contains(tipID) else { return }
        guard smartTipsService.canAutoOpen(
            tipID,
            smartTipsEnabled: smartTipsService.smartTipsEnabled,
            autoOpenEnabled: smartTipsService.autoOpenTipsEnabled
        ) else { return }
        lastAutoPresented.insert(tipID)
        activeSmartTip = smartTipsService.smartTip(for: tipID)
    }

    func resetDismissedSmartTips() {
        smartTipsService.resetDismissedTips()
        lastAutoPresented.removeAll()
    }

    // MARK: - ShiftTabView accessors

    var deliveryFloorNumbersForCurrentTower: [Int] {
        deliverySessionState.deliveryFloors
    }
    var remainingDeliveryFloorCount: Int {
        deliverySessionState.remainingCount
    }
    var completedDeliveryFloorCount: Int {
        deliverySessionState.completedCount
    }
    var currentTripItemNames: [String] {
        currentTripItemNamesSet
    }

    // MARK: - Current Trip (carry plan)

    var availableCurrentTripItems: [CalculationSummary] {
        // Only items that actually need to be delivered to at least one floor.
        let activeItemNames = Set(deliveryFloorDistributions
            .filter { ($0.suggestedBundles ?? 0) > 0 || $0.suggestedPieces > 0 }
            .map(\.itemName))
        return calculationSummaries.filter { activeItemNames.contains($0.itemName) }
    }

    var currentTripRangesByItem: [FloorRangeGroup] {
        let tripNames = Set(currentTripItemNamesSet)
        guard !tripNames.isEmpty else { return [] }
        let rows = deliveryFloorDistributions.filter { tripNames.contains($0.itemName) }
        return FloorRangeBuilder.build(from: rows, unitIsBundles: deliveryUnitIsBundles)
    }

    func toggleCurrentTripItem(_ itemName: String) {
        if let idx = currentTripItemNamesSet.firstIndex(of: itemName) {
            currentTripItemNamesSet.remove(at: idx)
        } else if currentTripItemNamesSet.count < Self.currentTripMaxItems {
            currentTripItemNamesSet.append(itemName)
        }
        persistCurrentTripItems()
        syncDeliverySessionState()
    }

    func clearCurrentTripItems() {
        guard !currentTripItemNamesSet.isEmpty else { return }
        currentTripItemNamesSet.removeAll()
        persistCurrentTripItems()
        syncDeliverySessionState()
    }

    private func restoreCurrentTripItems() {
        let raw = UserDefaults.standard.string(forKey: Self.currentTripItemsKey) ?? ""
        currentTripItemNamesSet = raw.isEmpty ? [] : raw.split(separator: ",").map(String.init)
    }

    private func persistCurrentTripItems() {
        let joined = currentTripItemNamesSet.prefix(Self.currentTripMaxItems).joined(separator: ",")
        UserDefaults.standard.set(joined, forKey: Self.currentTripItemsKey)
    }

    private func pruneCurrentTripItemsToAvailable() {
        let available = Set(availableCurrentTripItems.map(\.itemName))
        let pruned = currentTripItemNamesSet.filter { available.contains($0) }
        if pruned != currentTripItemNamesSet {
            currentTripItemNamesSet = pruned
            persistCurrentTripItems()
        }
    }
    
    // MARK: - SettingsView Stubs
    func updateTowerFloorRange(_ tower: Tower, startFloor: Int, topFloor: Int, skip13thFloor: Bool) {
        let newFloors = TowerFloorRange.deliveryFloors(
            startFloor: startFloor,
            topFloor: topFloor,
            skip13thFloor: skip13thFloor
        )
        guard !newFloors.isEmpty else { return }

        tower.startFloor = startFloor
        tower.topFloor = topFloor
        tower.skip13thFloor = skip13thFloor
        tower.floorCount = newFloors.count
        tower.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            saveError = "Could not save tower floors: \(error.localizedDescription)"
            return
        }

        refreshAvailable()

        if selectedTower?.id == tower.id {
            if deliverySessionState.isActive, deliverySessionState.towerName == tower.name {
                let preservedCompleted = deliverySessionState.completedFloorNumbers.intersection(Set(newFloors))
                deliverySessionState.deliveryFloors = newFloors
                deliverySessionState.floorCount = newFloors.count
                deliverySessionState.completedFloorNumbers = preservedCompleted
                if deliverySessionState.isComplete {
                    deliverySessionState.finishedAt = deliverySessionState.finishedAt ?? .now
                } else {
                    deliverySessionState.finishedAt = nil
                }
                syncDeliverySessionState()
            }
            recalculate()
        }
    }
    func eraseAllDataAndReset(isCustomProperty: Bool) {
        if deliverySessionState.isActive {
            resetDeliverySessionAndEndActivity()
        }
        selectedTower = nil
        receivingEntries.removeAll()
        currentTripItemNamesSet.removeAll()
        notes = ""
        isDemoDay = false
        activeSmartTip = nil
        lastAutoPresented.removeAll()
        currentDeliveryItemName = nil
        UserDefaults.standard.removeObject(forKey: Self.lastTowerIDKey)
        UserDefaults.standard.removeObject(forKey: Self.currentTripItemsKey)

        let logs = (try? modelContext.fetch(FetchDescriptor<DailyLog>())) ?? []
        for log in logs { modelContext.delete(log) }
        let items = (try? modelContext.fetch(FetchDescriptor<LinenItem>())) ?? []
        for item in items { modelContext.delete(item) }
        let towers = (try? modelContext.fetch(FetchDescriptor<Tower>())) ?? []
        for tower in towers { modelContext.delete(tower) }

        do {
            try modelContext.save()
        } catch {
            saveError = "Could not erase data: \(error.localizedDescription)"
        }

        UserDefaults.standard.set(isCustomProperty, forKey: "isCustomProperty")

        SeedService.seedIfNeeded(context: modelContext, isCustomProperty: isCustomProperty)

        refreshAvailable()
        recalculate()
    }
    func resetTowerFloorRangeToDefaults(_ tower: Tower) {
        let seed = DefaultData.towers.first(where: { $0.name == tower.name })

        if let seed {
            if seed.startFloor >= 1, seed.topFloor >= seed.startFloor {
                tower.startFloor = seed.startFloor
                tower.topFloor = seed.topFloor
                tower.skip13thFloor = seed.skip13thFloor
                tower.floorCount = TowerFloorRange.deliveryFloorCount(
                    startFloor: seed.startFloor,
                    topFloor: seed.topFloor,
                    skip13thFloor: seed.skip13thFloor
                )
            } else {
                // Seeded tower with no simple range (e.g., GW legacy multi-gap).
                // Unset the editable range to fall back to the legacy sequence.
                tower.startFloor = 0
                tower.topFloor = 0
                tower.skip13thFloor = false
                tower.floorCount = seed.floorCount
            }
        } else {
            // User-created tower has no seed: reset to a simple 1..floorCount range.
            let safeTop = max(tower.floorCount, 1)
            tower.startFloor = 1
            tower.topFloor = safeTop
            tower.skip13thFloor = false
            tower.floorCount = safeTop
        }
        tower.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            saveError = "Could not reset tower floors: \(error.localizedDescription)"
            return
        }

        refreshAvailable()

        if selectedTower?.id == tower.id {
            let newFloors = DeliveryFloorSequenceService.deliveryFloors(for: tower)
            if deliverySessionState.isActive, deliverySessionState.towerName == tower.name {
                let preservedCompleted = deliverySessionState.completedFloorNumbers.intersection(Set(newFloors))
                deliverySessionState.deliveryFloors = newFloors
                deliverySessionState.floorCount = newFloors.count
                deliverySessionState.completedFloorNumbers = preservedCompleted
                syncDeliverySessionState()
            }
            recalculate()
        }
    }

    func addTower(
        name: String,
        startFloor: Int,
        topFloor: Int,
        skip13thFloor: Bool,
        deliveryMode: TowerDeliveryMode,
        identityColorHex: String? = nil
    ) -> Tower? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let existingNames = Set(((try? modelContext.fetch(FetchDescriptor<Tower>())) ?? []).map { $0.name.lowercased() })
        guard !existingNames.contains(trimmed.lowercased()) else { return nil }

        let floors = TowerFloorRange.deliveryFloors(
            startFloor: startFloor,
            topFloor: topFloor,
            skip13thFloor: skip13thFloor
        )
        guard !floors.isEmpty else { return nil }

        let tower = Tower(
            name: trimmed,
            floorCount: floors.count,
            isActive: true,
            identityColorHex: identityColorHex,
            deliveryMode: deliveryMode,
            startFloor: startFloor,
            topFloor: topFloor,
            skip13thFloor: skip13thFloor
        )
        modelContext.insert(tower)

        do {
            try modelContext.save()
        } catch {
            saveError = "Could not save new tower: \(error.localizedDescription)"
            return nil
        }

        refreshAvailable()
        return tower
    }

    func deleteTower(_ tower: Tower) {
        if selectedTower?.id == tower.id {
            if deliverySessionState.isActive, deliverySessionState.towerName == tower.name {
                resetDeliverySessionAndEndActivity()
            }
            selectedTower = nil
            UserDefaults.standard.removeObject(forKey: Self.lastTowerIDKey)
            receivingEntries.removeAll()
            recalculate()
        }
        modelContext.delete(tower)
        do {
            try modelContext.save()
        } catch {
            saveError = "Could not delete tower: \(error.localizedDescription)"
        }
        refreshAvailable()
    }

    func setTowerActive(_ tower: Tower, isActive: Bool) {
        guard tower.isActive != isActive else { return }
        tower.isActive = isActive
        tower.updatedAt = .now
        try? modelContext.save()
        refreshAvailable()
    }

    // MARK: - Live Activity Processor
    var nextUndoneDeliveryFloor: Int? {
        deliverySessionState.deliveryFloors.first(where: { !deliverySessionState.completedFloorNumbers.contains($0) })
    }

    func nextUndoneFloor() -> Int? {
        nextUndoneDeliveryFloor
    }

    func itemsNeededOnFloor(_ floorNumber: Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for row in deliveryFloorDistributions
        where row.floorNumber == floorNumber && deliveryAmount(for: row) > 0 {
            if seen.insert(row.itemName).inserted {
                result.append(row.itemName)
            }
        }
        return result
    }

    func deliveryAmounts(onFloor floorNumber: Int) -> [FloorDeliveryAmount] {
        deliveryFloorDistributions
            .filter { $0.floorNumber == floorNumber }
            .compactMap { row in
                let amount = deliveryAmount(for: row)
                guard amount > 0 else { return nil }
                return FloorDeliveryAmount(
                    id: "\(floorNumber)-\(row.itemName)",
                    floorNumber: floorNumber,
                    itemName: row.itemName,
                    amount: amount,
                    unit: deliveryUnitLabel
                )
            }
            .sorted { lhs, rhs in
                if lhs.amount != rhs.amount { return lhs.amount > rhs.amount }
                return lhs.itemName < rhs.itemName
            }
    }

    private var deliveryUnitLabel: String {
        deliveryUnitIsBundles ? "bdl" : "pcs"
    }

    private func deliveryAmount(for row: FloorDistributionRow) -> Int {
        deliveryUnitIsBundles ? (row.suggestedBundles ?? row.suggestedPieces) : row.suggestedPieces
    }

    func markFloorCompleteAndAdvance(_ floorNumber: Int) {
        ensureDeliverySessionPrepared()
        guard deliverySessionState.deliveryFloors.contains(floorNumber) else { return }

        let inserted = deliverySessionState.completedFloorNumbers.insert(floorNumber).inserted
        guard inserted else { return }
        lastCompletedFloorNumber = floorNumber

        if deliverySessionState.isComplete {
            deliverySessionState.finishedAt = deliverySessionState.finishedAt ?? .now
        } else if nextUndoneDeliveryFloor != nil,
                  deliverySessionState.nextCarryGroupTitle == nil {
            deliverySessionState.nextCarryGroupTitle = carryGroups.first?.label
        }

        syncDeliverySessionState()
    }

    func processPendingLiveActivityDrops() {
        if let defaults = UserDefaults(suiteName: SharedWidgetStateManager.appGroupID) {
            let pendingFloors = defaults.array(forKey: Self.pendingLiveActivityDropFloorsKey) as? [Int] ?? []
            if !pendingFloors.isEmpty {
                AppLogger.session.info("Processing \(pendingFloors.count) pending Live Activity floor drops")
                var appliedFloors = Set<Int>()
                for floor in pendingFloors where appliedFloors.insert(floor).inserted {
                    markFloorCompleteAndAdvance(floor)
                }
                defaults.set([], forKey: Self.pendingLiveActivityDropFloorsKey)
                defaults.set(0, forKey: Self.pendingLiveActivityDropsKey)

                if deliverySessionState.isComplete {
                    finishDeliverySession()
                }
            }

            let undoFloors = defaults.array(forKey: Self.pendingLiveActivityUndoFloorsKey) as? [Int] ?? []
            if !undoFloors.isEmpty {
                AppLogger.session.info("Processing \(undoFloors.count) pending Live Activity floor undos")
                for floor in undoFloors {
                    undoCompletedFloorFromWidget(floor)
                }
                defaults.set([], forKey: Self.pendingLiveActivityUndoFloorsKey)
            }

            let pending = defaults.integer(forKey: Self.pendingLiveActivityDropsKey)
            if pending > 0 {
                AppLogger.session.info("Processing \(pending) pending Live Activity drops from Lock Screen")
                for _ in 0..<pending {
                    if let nextFloor = nextUndoneDeliveryFloor {
                        markFloorCompleteAndAdvance(nextFloor)
                    }
                }
                defaults.set(0, forKey: Self.pendingLiveActivityDropsKey)
                
                if deliverySessionState.isComplete {
                    finishDeliverySession()
                }
            }
        }
    }

    func setNextCarryGroup(_ title: String?) {
        deliverySessionState.nextCarryGroupTitle = title
        syncDeliverySessionState()
    }

    // MARK: - Calculations

    func recalculate() {
        guard let tower = selectedTower else {
            calculationSummaries = []
            floorDistributions = []
            bundleFloorDistributions = []
            validateInputs()
            syncWidgetState()
            return
        }

        let aggregated = ReceivingAggregationAlgorithm.aggregate(receivingEntries)

        var summaries: [CalculationSummary] = []
        var distributions: [FloorDistributionRow] = []
        var bundleDistributions: [FloorDistributionRow] = []
        let towerUsesParSystem = TowerOperationalPolicy.usesParSystem(for: tower)
        let deliveryFloorCount = DeliveryFloorSequenceService.deliveryFloors(for: tower).count

        for row in aggregated {
            let itemName = row.itemName
            let totalPieces = row.totalPieces
            guard let item = availableItems.first(where: { $0.name == itemName }) else { continue }
            let summary = towerUsesParSystem
                ? LinenCalculatorService.calculateSummary(
                    itemName: itemName,
                    receivedPieces: totalPieces,
                    floorCount: deliveryFloorCount,
                    parCount: item.parCount,
                    bundleSize: item.bundleSize,
                    parCountsBundles: tower.deliveryMode != .pieces
                )
                : LinenCalculatorService.calculateNoParSummary(
                    itemName: itemName,
                    receivedPieces: totalPieces,
                    floorCount: deliveryFloorCount,
                    bundleSize: item.bundleSize
                )
            summaries.append(summary)

            distributions.append(contentsOf: LinenCalculatorService.calculateFloorDistribution(
                receivedPieces: totalPieces,
                floorCount: deliveryFloorCount,
                itemName: itemName
            ))

            let bundleRows = towerUsesParSystem
                ? LinenCalculatorService.calculateCappedBundleFloorDistribution(
                    fullBundles: summary.fullBundles,
                    floorCount: deliveryFloorCount,
                    parPerFloor: item.parCount,
                    itemName: itemName
                )
                : LinenCalculatorService.calculateBundleFloorDistribution(
                    fullBundles: summary.fullBundles,
                    floorCount: deliveryFloorCount,
                    itemName: itemName
                )
            bundleDistributions.append(contentsOf: bundleRows)
        }

        calculationSummaries = summaries.sorted { $0.itemName < $1.itemName }
        floorDistributions = FloorNumberingService.applyDisplayFloors(distributions, tower: tower).sorted {
            $0.floorNumber == $1.floorNumber ? $0.itemName < $1.itemName : $0.floorNumber < $1.floorNumber
        }
        bundleFloorDistributions = FloorNumberingService.applyDisplayFloors(bundleDistributions, tower: tower).sorted {
            $0.floorNumber == $1.floorNumber ? $0.itemName < $1.itemName : $0.floorNumber < $1.floorNumber
        }
        pruneCurrentTripItemsToAvailable()
        validateInputs()
        syncWidgetState()
    }

    var usesPieceDelivery: Bool {
        guard let tower = selectedTower else { return false }
        return tower.deliveryMode == .pieces
    }

    var prefersBundleDelivery: Bool { !usesPieceDelivery }

    var deliveryFloorDistributions: [FloorDistributionRow] {
        usesPieceDelivery ? floorDistributions : bundleFloorDistributions
    }

    var deliveryUnitIsBundles: Bool { !usesPieceDelivery }

    var usesParSystem: Bool {
        TowerOperationalPolicy.usesParSystem(for: selectedTower)
    }

    var carryGroups: [CarryGroup] {
        CarryGroupBuilder().build(
            entries: receivingEntries,
            summaries: calculationSummaries
        )
    }

    func validateInputs() {
        var warnings: [String] = []

        if selectedTower == nil {
            warnings.append("Select a tower to begin.")
        }
        if receivingEntries.isEmpty {
            warnings.append("Enter at least one received item.")
        }
        for entry in receivingEntries {
            switch entry.countMethod {
            case .fixedBin:
                if (entry.binCount ?? 0) <= 0 {
                    warnings.append("\(entry.itemName): enter a bin count.")
                }
            case .manualPieces, .cartLabelPieces:
                if (entry.manualPieces ?? 0) <= 0 {
                    warnings.append("\(entry.itemName): enter received pieces.")
                }
            }
        }
        if let tower = selectedTower {
            if tower.floorCount <= 0 {
                warnings.append("\(tower.name): floor count must be greater than 0.")
            }
            let doubleItems = Set(receivingEntries.map(\.itemName)).intersection(["Double Sheet", "Double Cover"])
            if !doubleItems.isEmpty, !tower.allowsDoubleItems {
                let names = doubleItems.sorted().joined(separator: ", ")
                warnings.append("\(names) is normally only used in Diamond and Alii towers.")
            }
        }
        for item in availableItems {
            if item.parCount < 0 {
                warnings.append("\(item.name): par cannot be negative.")
            }
            if item.bundleSize <= 0 {
                warnings.append("\(item.name): bundle size must be greater than 0.")
            }
        }
        if !usesPieceDelivery {
            for summary in calculationSummaries where summary.loosePieces > 0 {
                warnings.append("\(summary.itemName): \(summary.loosePieces) loose pieces will not be delivered as bundles.")
            }
        }
        for summary in calculationSummaries {
            if summary.receivedPieces > 0, summary.fullBundles == 0 {
                warnings.append("\(summary.itemName): received pieces do not make a full bundle. Recount or add pieces before delivery.")
            }
            if summary.bundleSize > 0, summary.loosePieces * 2 >= summary.bundleSize {
                warnings.append("\(summary.itemName): \(summary.loosePieces) loose pieces is close to another bundle. Recheck the count.")
            }
            if summary.shortageBundles > 0 {
                warnings.append("\(summary.itemName): short \(summary.shortageBundles) bundles against par cap.")
            } else if summary.status == .shortage, summary.differencePieces < 0 {
                warnings.append("\(summary.itemName): short \(abs(summary.differencePieces)) pcs against par.")
            }
        }

        supplyAnomalies = shiftIntelligence.anomalies(
            entries: receivingEntries,
            predictions: supplyPredictions
        )
        for anomaly in supplyAnomalies {
            warnings.append(anomaly.message)
        }

        validationWarnings = warnings
    }

    // MARK: - Shift intelligence

    func updateShiftIntelligence(from logs: [DailyLog]) {
        guard let tower = selectedTower else {
            supplyPredictions = []
            supplyAnomalies = []
            return
        }
        let towerItems = availableItems.filter { itemIsAvailable($0, for: tower) }
        supplyPredictions = shiftIntelligence.predictions(
            towerName: tower.name,
            items: towerItems,
            logs: logs
        )
        supplyAnomalies = shiftIntelligence.anomalies(
            entries: receivingEntries,
            predictions: supplyPredictions
        )
    }

    var smartFillItemCount: Int {
        supplyPredictions.filter(\.hasValue).count
    }

    var smartFillSummary: String? {
        guard smartFillItemCount > 0 else { return nil }
        let label = supplyPredictions.first?.typicalLabel ?? "Historical average"
        return "\(label) · \(smartFillItemCount) items"
    }

    @discardableResult
    func applySmartFill() -> Int {
        guard selectedTower != nil else { return 0 }
        let itemByName = Dictionary(uniqueKeysWithValues: availableItems.map { ($0.name, $0) })
        var applied = 0
        for prediction in supplyPredictions where prediction.hasValue {
            guard let item = itemByName[prediction.itemName],
                  itemIsAvailable(item, for: selectedTower!) else { continue }
            switch item.countMethod {
            case .fixedBin:
                if let bins = prediction.predictedBins {
                    addOrUpdateReceivingEntry(item: item, binCount: bins, notes: "Smart fill")
                    applied += 1
                }
            case .manualPieces, .cartLabelPieces:
                if let pieces = prediction.predictedPieces {
                    addOrUpdateReceivedPieces(item: item, pieces: pieces)
                    applied += 1
                }
            }
        }
        return applied
    }

    // MARK: - Flow control

    /// Clears all entered items but keeps the tower selected — use for the "Clear" action during a shift.
    func clearEntries() {
        receivingEntries = []
        calculationSummaries = []
        floorDistributions = []
        bundleFloorDistributions = []
        currentDeliveryItemName = nil
        deliverySessionState = DeliverySessionState()
        notes = ""
        isDemoDay = false
        supplyAnomalies = []
        LiveActivityManager.endDeliveryActivity(state: deliverySessionState)
        recalculate()
    }

    /// Restores a saved log as editable receiving input, then recalculates using current tower/item settings.
    func loadFromLog(_ log: DailyLog) {
        if selectedTower?.name != log.towerName,
           let tower = availableTowers.first(where: { $0.name == log.towerName }) {
            selectTower(tower)
        }

        let availableItemNames = Set(availableItems.map(\.name))
        receivingEntries = log.entriesSnapshot.filter { availableItemNames.contains($0.itemName) }
        currentDeliveryItemName = nil
        deliverySessionState = DeliverySessionState()
        notes = log.notes
        isDemoDay = false
        recalculate()
    }

    /// Full reset including tower selection — use for demo loads and fresh starts.
    func resetFlow() {
        selectedTower = nil
        UserDefaults.standard.removeObject(forKey: Self.lastTowerIDKey)
        receivingEntries = []
        calculationSummaries = []
        floorDistributions = []
        bundleFloorDistributions = []
        currentDeliveryItemName = nil
        deliverySessionState = DeliverySessionState()
        notes = ""
        validationWarnings = []
        isDemoDay = false
        LiveActivityManager.endDeliveryActivity(state: deliverySessionState)
        syncWidgetState()
    }

    // MARK: - Demo fixtures

    func loadDemoDay() {
        resetFlow()
        refreshAvailable()
        isDemoDay = true

        guard let lagoon = availableTowers.first(where: { $0.name == "Lagoon" }) else {
            syncWidgetState()
            return
        }
        selectTower(lagoon)

        let demoSpecs: [(name: String, binCount: Int?, manualPieces: Int?)] = [
            ("Bath Towel",  2,   nil),
            ("Bath Mat",    nil, 60),
            ("Hand Towel",  nil, 100),
            ("Washcloth",   nil, 40),
            ("Pillow Case", nil, 90),
        ]

        for spec in demoSpecs {
            guard let item = availableItems.first(where: { $0.name == spec.name }) else { continue }
            addOrUpdateReceivingEntry(item: item, binCount: spec.binCount, manualPieces: spec.manualPieces)
        }
        syncWidgetState()
    }

    func loadDiamondDHeadExample() {
        resetFlow()
        refreshAvailable()
        isDemoDay = true

        guard let diamond = availableTowers.first(where: { $0.name == "Diamond" }) else {
            syncWidgetState()
            return
        }
        selectTower(diamond)
        notes = "ALSCO D-Head 05/14/26 — Carts 1801, 7045, 1406"

        let rows: [(cart: String, rawName: String, pieces: Int)] = [
            ("1801", "Double Duvet",            51),
            ("1801", "Double Sheet",            39),
            ("7045", "King Sheet",              50),
            ("7045", "King Duvet / King Cover", 50),
            ("1406", "Double Sheet",            50),
            ("1406", "Double Duvet",            65),
        ]

        for row in rows {
            let canonical = BundleLibrary.canonicalName(for: row.rawName)
            guard let item = availableItems.first(where: { $0.name == canonical }) else { continue }
            addCartLabelRow(item: item, pieces: row.pieces, cartNumber: row.cart)
        }
        syncWidgetState()
    }

    func syncWidgetState(
        shiftSettings: ShiftSettings? = nil,
        completedFloors: Int = 0,
        currentItemName: String? = nil,
        nextCarryGroupTitle: String? = nil,
        isActiveSession: Bool = false,
        allowsCurrentItemFallback: Bool = true,
        preserveExistingActiveSession: Bool = false
    ) {
        if preserveExistingActiveSession {
            let existingState = SharedWidgetStateManager.load()
            if existingState.isActiveSession, !deliverySessionState.isActive {
                return
            }
        }

        let effectiveShiftSettings = shiftSettings ?? widgetShiftSettings
        guard let tower = selectedTower else {
            SharedWidgetStateManager.save(SharedWidgetStateManager.defaultState())
            WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
            return
        }

        let towerDeliveryFloorCount = DeliveryFloorSequenceService.deliveryFloors(for: tower).count
        let sessionFloorCount = deliverySessionState.deliveryFloors.isEmpty ? towerDeliveryFloorCount : deliverySessionState.floorCount
        let sessionIsActive = isActiveSession || deliverySessionState.isActive

        // When a session is active, derive completed/carry from real session state so
        // callers (e.g. recalculate) don't accidentally pass stale defaults.
        let effectiveCompleted = deliverySessionState.isActive ? deliverySessionState.completedCount : completedFloors
        let effectiveNextCarry = (deliverySessionState.isActive && nextCarryGroupTitle == nil)
            ? deliverySessionState.nextCarryGroupTitle
            : nextCarryGroupTitle

        let floorCount = sessionIsActive ? sessionFloorCount : towerDeliveryFloorCount
        let remainingFloors = max(floorCount - effectiveCompleted, 0)
        let shiftWindow = effectiveShiftSettings.map {
            WorkShiftWindow.containing(
                .now,
                startHour: $0.shiftStartHour,
                startMinute: $0.shiftStartMinute,
                endHour: $0.shiftEndHour,
                endMinute: $0.shiftEndMinute
            )
        }
        let fallbackCurrentItemName = allowsCurrentItemFallback ? (currentDeliveryItemName ?? calculationSummaries.first?.itemName) : nil
        let selectedCurrentItemName = currentItemName ?? fallbackCurrentItemName
        let selectedRows = widgetFloorPlanRows(for: selectedCurrentItemName)
        let statusText: String
        if deliverySessionState.isPaused {
            statusText = "Paused at \(effectiveCompleted)/\(floorCount) floors"
        } else if sessionIsActive {
            statusText = "\(effectiveCompleted)/\(floorCount) floors complete"
        } else {
            statusText = "Ready for \(tower.name)"
        }
        let pinned = pinnedWidgetItemNames
        let calculatedNames = Set(calculationSummaries.map(\.itemName))
        let resolvedPinned = pinned.filter { calculatedNames.contains($0) }
        let allItemNames = resolvedPinned.isEmpty
            ? Array(calculationSummaries.prefix(3).map(\.itemName))
            : Array(resolvedPinned.prefix(3))

        var state = SharedWidgetState(
            towerName: tower.name,
            towerColorHex: tower.identityColorHex,
            floorCount: floorCount,
            completedFloors: effectiveCompleted,
            remainingFloors: remainingFloors,
            targetTime: effectiveShiftSettings?.widgetTargetTime(),
            shiftStartTime: shiftWindow?.start,
            shiftEndTime: shiftWindow?.end,
            currentItemName: selectedCurrentItemName,
            currentItemFloorPlanTitle: selectedRows.isEmpty ? nil : "Top down per floor",
            currentItemFloorPlanRows: selectedRows.isEmpty ? nil : selectedRows,
            nextCarryGroupTitle: effectiveNextCarry,
            statusText: statusText,
            lastUpdated: .now,
            isActiveSession: sessionIsActive,
            isDemoDay: isDemoDay
        )
        state.isPausedSession = deliverySessionState.isPaused
        state.currentItemNames = allItemNames.isEmpty ? nil : Array(allItemNames)
        let tripNames = Array(currentTripItemNamesSet.prefix(Self.currentTripMaxItems))
        state.currentTripItemNames = tripNames.isEmpty ? state.currentItemNames?.prefix(Self.currentTripMaxItems).map { $0 } : tripNames
        let hasDeliveryProjection = !deliverySessionState.deliveryFloors.isEmpty && (sessionIsActive || deliverySessionState.isComplete)
        state.currentFloorNumber = sessionIsActive ? nextUndoneDeliveryFloor : nil
        state.deliveryFloorNumbers = hasDeliveryProjection ? deliverySessionState.deliveryFloors : nil
        state.completedFloorNumbers = hasDeliveryProjection ? Array(deliverySessionState.completedFloorNumbers).sorted() : nil
        state.lastCompletedFloorNumber = lastCompletedFloorNumber
        let deliveryAmountsByFloor = hasDeliveryProjection
            ? widgetDeliveryAmountsByFloor(itemNames: state.currentTripItemNames ?? [])
            : nil
        state.floorDeliveryAmountsByFloor = deliveryAmountsByFloor
        state.currentFloorDeliveryAmounts = state.currentFloorNumber.map {
            deliveryAmountsByFloor?[$0] ?? widgetDeliveryAmounts(onFloor: $0, itemNames: state.currentTripItemNames ?? [])
        }
        let bundleProgress = widgetBundleProgress(
            amountsByFloor: deliveryAmountsByFloor,
            completedFloors: deliverySessionState.completedFloorNumbers
        )
        state.currentTripTotalBundles = bundleProgress.total > 0 ? bundleProgress.total : nil
        state.currentTripRemainingBundles = bundleProgress.total > 0 ? bundleProgress.remaining : nil

        SharedWidgetStateManager.save(state)
        WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
        if state.isActiveSession {
            LiveActivityManager.updateDeliveryActivity(from: state)
        }
    }

    func buildDailyLog() -> DailyLog? {
        guard let tower = selectedTower, !receivingEntries.isEmpty else { return nil }
        return DailyLog(
            date: .now,
            towerName: tower.name,
            floorCount: DeliveryFloorSequenceService.deliveryFloors(for: tower).count,
            entriesSnapshot: receivingEntries,
            summarySnapshot: calculationSummaries,
            distributionSnapshot: deliveryFloorDistributions,
            notes: notes
        )
    }

    // MARK: - Private

    private func ensureDeliverySessionPrepared() {
        guard let tower = selectedTower else { return }
        let floors = DeliveryFloorSequenceService.deliveryFloors(for: tower)
        guard deliverySessionState.towerName != tower.name || deliverySessionState.deliveryFloors.isEmpty else { return }

        deliverySessionState.towerName = tower.name
        deliverySessionState.floorCount = floors.count
        deliverySessionState.deliveryFloors = floors
        deliverySessionState.completedFloorNumbers = deliverySessionState.completedFloorNumbers.intersection(Set(floors))
    }

    private func syncDeliverySessionState(startActivity: Bool = false, endActivity: Bool = false) {
        ensureDeliverySessionPrepared()
        syncWidgetState(
            completedFloors: deliverySessionState.completedCount,
            currentItemName: deliverySessionState.currentItemName,
            nextCarryGroupTitle: deliverySessionState.nextCarryGroupTitle,
            isActiveSession: deliverySessionState.isActive,
            allowsCurrentItemFallback: false
        )

        if endActivity {
            LiveActivityManager.endDeliveryActivity(state: deliverySessionState)
            return
        }

        let liveState = SharedWidgetStateManager.load()
        if startActivity {
            LiveActivityManager.startDeliveryActivity(from: liveState)
        }
    }


    private static func migrateLegacyUserDefaultsKeys() {
        guard !UserDefaults.standard.bool(forKey: legacyUserDefaultsMigrationKey) else { return }
        for mapping in legacyUserDefaultsKeyMappings {
            guard UserDefaults.standard.object(forKey: mapping.current) == nil,
                  let value = UserDefaults.standard.object(forKey: mapping.legacy) else { continue }
            UserDefaults.standard.set(value, forKey: mapping.current)
            UserDefaults.standard.removeObject(forKey: mapping.legacy)
        }
        UserDefaults.standard.set(true, forKey: legacyUserDefaultsMigrationKey)
    }

    private func restoreLastSelectedTower() {
        guard let idString = UserDefaults.standard.string(forKey: Self.lastTowerIDKey),
              let id = UUID(uuidString: idString),
              let tower = availableTowers.first(where: { $0.id == id }) else { return }
        selectedTower = tower
    }

    private func restoreDeliverySessionFromSharedWidgetStateIfNeeded() {
        guard !deliverySessionState.isActive else { return }
        let state = SharedWidgetStateManager.load()
        guard state.floorCount > 0,
              state.isActiveSession || state.currentFloorNumber != nil || state.remainingFloors == 0,
              let tower = selectedTower,
              state.towerName == tower.name else { return }

        let floors = state.deliveryFloorNumbers ?? DeliveryFloorSequenceService.deliveryFloors(for: tower)
        guard !floors.isEmpty else { return }
        let completed = Set(state.completedFloorNumbers ?? [])
        deliverySessionState = DeliverySessionState(
            isActive: state.remainingFloors > 0,
            isPaused: state.isPausedSession ?? false,
            towerName: tower.name,
            floorCount: floors.count,
            deliveryFloors: floors,
            completedFloorNumbers: completed.intersection(Set(floors)),
            currentItemName: state.currentItemName,
            nextCarryGroupTitle: state.nextCarryGroupTitle,
            startedAt: nil,
            pausedAt: nil,
            finishedAt: state.remainingFloors == 0 ? state.lastUpdated : nil
        )
        currentDeliveryItemName = state.currentItemName
        lastCompletedFloorNumber = state.lastCompletedFloorNumber
    }

    private func undoCompletedFloorFromWidget(_ floorNumber: Int) {
        ensureDeliverySessionPrepared()
        guard deliverySessionState.deliveryFloors.contains(floorNumber),
              deliverySessionState.completedFloorNumbers.contains(floorNumber) else { return }

        deliverySessionState.completedFloorNumbers.remove(floorNumber)
        deliverySessionState.isActive = true
        deliverySessionState.isPaused = false
        deliverySessionState.finishedAt = nil
        if lastCompletedFloorNumber == floorNumber {
            lastCompletedFloorNumber = nil
        }
        syncDeliverySessionState()
    }

    private func widgetDeliveryAmountsByFloor(itemNames: [String]) -> [Int: [WidgetFloorDeliveryAmount]] {
        let floors = deliverySessionState.deliveryFloors.isEmpty
            ? Array(Set(deliveryFloorDistributions.map(\.floorNumber))).sorted()
            : deliverySessionState.deliveryFloors

        return floors.reduce(into: [:]) { result, floor in
            let amounts = widgetDeliveryAmounts(onFloor: floor, itemNames: itemNames)
            if !amounts.isEmpty {
                result[floor] = amounts
            }
        }
    }

    private func widgetDeliveryAmounts(onFloor floorNumber: Int, itemNames: [String]) -> [WidgetFloorDeliveryAmount] {
        let itemFilter = Set(itemNames)
        return deliveryFloorDistributions
            .filter { row in
                row.floorNumber == floorNumber && (itemFilter.isEmpty || itemFilter.contains(row.itemName))
            }
            .compactMap { row in
                let amount = widgetBundleAmount(for: row)
                guard amount.bundles > 0 || amount.loosePieces > 0 else { return nil }
                return WidgetFloorDeliveryAmount(
                    itemName: row.itemName,
                    bundles: amount.bundles,
                    loosePieces: amount.loosePieces
                )
            }
            .sorted { lhs, rhs in
                if lhs.bundles != rhs.bundles { return lhs.bundles > rhs.bundles }
                if lhs.loosePieces != rhs.loosePieces { return lhs.loosePieces > rhs.loosePieces }
                return lhs.itemName < rhs.itemName
            }
    }

    private func widgetBundleAmount(for row: FloorDistributionRow) -> (bundles: Int, loosePieces: Int) {
        if let bundles = row.suggestedBundles {
            return (max(bundles, 0), 0)
        }

        guard let item = availableItems.first(where: { $0.name == row.itemName }),
              item.bundleSize > 0 else {
            return (0, max(row.suggestedPieces, 0))
        }

        let converted = LinenCalculatorService.convertPiecesToBundles(
            pieces: max(row.suggestedPieces, 0),
            bundleSize: item.bundleSize
        )
        return (converted.fullBundles, converted.loosePieces)
    }

    private func widgetBundleProgress(
        amountsByFloor: [Int: [WidgetFloorDeliveryAmount]]?,
        completedFloors: Set<Int>
    ) -> (remaining: Int, total: Int) {
        guard let amountsByFloor else { return (0, 0) }
        var total = 0
        var remaining = 0
        for (floor, amounts) in amountsByFloor {
            let floorBundles = amounts.reduce(0) { $0 + max($1.bundles, 0) }
            total += floorBundles
            if !completedFloors.contains(floor) {
                remaining += floorBundles
            }
        }
        return (remaining, total)
    }

    private func makeEntry(item: LinenItem, binCount: Int?, manualPieces: Int?, physicalBinCount: Int? = nil, notes: String?) -> ReceivingEntry {
        switch item.countMethod {
        case .fixedBin:
            let bins = max(0, binCount ?? 0)
            let pieces = bins * (item.piecesPerBin ?? 0)
            let (full, loose) = LinenCalculatorService.convertPiecesToBundles(pieces: pieces, bundleSize: item.bundleSize)
            return ReceivingEntry(
                itemName: item.name,
                countMethod: .fixedBin,
                binCount: bins,
                physicalBinCount: physicalBinCount,
                manualPieces: nil,
                piecesPerBin: item.piecesPerBin,
                calculatedPieces: pieces,
                calculatedFullBundles: full,
                loosePieces: loose,
                notes: notes
            )
        case .manualPieces, .cartLabelPieces:
            let p = max(0, manualPieces ?? 0)
            let (full, loose) = LinenCalculatorService.convertPiecesToBundles(pieces: p, bundleSize: item.bundleSize)
            return ReceivingEntry(
                itemName: item.name,
                countMethod: item.countMethod,
                binCount: nil,
                physicalBinCount: physicalBinCount,
                manualPieces: p,
                piecesPerBin: nil,
                calculatedPieces: p,
                calculatedFullBundles: full,
                loosePieces: loose,
                notes: notes
            )
        }
    }

    /// Atomically resets the delivery session and ends the Live Activity using the last known state.
    private func resetDeliverySessionAndEndActivity() {
        let stateSnapshot = deliverySessionState
        deliverySessionState = DeliverySessionState()
        currentDeliveryItemName = nil
        LiveActivityManager.endDeliveryActivity(state: stateSnapshot)
    }

    private func widgetFloorPlanRows(for itemName: String?) -> [WidgetFloorPlanRow] {
        guard let itemName else { return [] }
        return WidgetFloorPlanAlgorithm.buildRows(
            distributions: deliveryFloorDistributions,
            itemName: itemName,
            unitIsBundles: deliveryUnitIsBundles
        )
    }
}
