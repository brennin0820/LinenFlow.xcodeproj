import Foundation

final class SmartTipsService {
    private let defaults: UserDefaults

    private let dismissedTipIDsKey = "himmerflow.smartTips.dismissedTipIDs"
    private let smartTipsEnabledKey = "himmerflow.smartTips.enabled"
    private let autoOpenTipsEnabledKey = "himmerflow.smartTips.autoOpenEnabled"
    private let showTipButtonsKey = "himmerflow.smartTips.showTipButtons"
    private let legacyKeyMappings: [(legacy: String, current: String)] = [
        ("linenflow.smartTips.dismissedTipIDs", "himmerflow.smartTips.dismissedTipIDs"),
        ("linenflow.smartTips.enabled", "himmerflow.smartTips.enabled"),
        ("linenflow.smartTips.autoOpenEnabled", "himmerflow.smartTips.autoOpenEnabled"),
        ("linenflow.smartTips.showTipButtons", "himmerflow.smartTips.showTipButtons"),
    ]
    private let migrationCompletedKey = "himmerflow.migratedSmartTipsFromLinenFlow"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        migrateLegacyKeys()
    }

    private func migrateLegacyKeys() {
        guard !defaults.bool(forKey: migrationCompletedKey) else { return }
        for mapping in legacyKeyMappings {
            guard defaults.object(forKey: mapping.current) == nil,
                  let value = defaults.object(forKey: mapping.legacy) else { continue }
            defaults.set(value, forKey: mapping.current)
            defaults.removeObject(forKey: mapping.legacy)
        }
        defaults.set(true, forKey: migrationCompletedKey)
    }

    var smartTipsEnabled: Bool {
        get { bool(forKey: smartTipsEnabledKey, defaultValue: true) }
        set { defaults.set(newValue, forKey: smartTipsEnabledKey) }
    }

    var autoOpenTipsEnabled: Bool {
        get { bool(forKey: autoOpenTipsEnabledKey, defaultValue: true) }
        set { defaults.set(newValue, forKey: autoOpenTipsEnabledKey) }
    }

    var showTipButtons: Bool {
        get { bool(forKey: showTipButtonsKey, defaultValue: true) }
        set { defaults.set(newValue, forKey: showTipButtonsKey) }
    }

    func smartTip(for id: SmartTipID) -> SmartTip {
        Self.catalog[id] ?? SmartTip(
            id: id,
            title: "Smart Tip",
            message: "Helpful HimmerFlow guidance is available for this workflow step.",
            category: .settings,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "lightbulb.fill",
            actionTitle: nil
        )
    }

    func isDismissed(_ id: SmartTipID) -> Bool {
        dismissedTipIDs.contains(id.rawValue)
    }

    func markDismissed(_ id: SmartTipID) {
        var ids = dismissedTipIDs
        ids.insert(id.rawValue)
        saveDismissedTipIDs(ids)
    }

    func resetDismissedTips() {
        defaults.removeObject(forKey: dismissedTipIDsKey)
    }

    func canAutoOpen(_ id: SmartTipID, smartTipsEnabled: Bool, autoOpenEnabled: Bool) -> Bool {
        let tip = smartTip(for: id)
        return smartTipsEnabled
            && autoOpenEnabled
            && tip.allowsAutoOpen
            && !isDismissed(id)
    }

    func canPresentManually(_ id: SmartTipID, smartTipsEnabled: Bool, force: Bool) -> Bool {
        smartTipsEnabled && (force || !isDismissed(id))
    }

    private var dismissedTipIDs: Set<String> {
        Set(defaults.stringArray(forKey: dismissedTipIDsKey) ?? [])
    }

    private func saveDismissedTipIDs(_ ids: Set<String>) {
        defaults.set(Array(ids).sorted(), forKey: dismissedTipIDsKey)
    }

    private func bool(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }
}

private extension SmartTipsService {
    static let catalog: [SmartTipID: SmartTip] = [
        .towerSeparateSupply: SmartTip(
            id: .towerSeparateSupply,
            title: "Tower Supplies Stay Separate",
            message: "Each tower or area is calculated separately. Do not mix received linen between towers unless you intentionally move stock.",
            category: .tower,
            priority: .important,
            allowsAutoOpen: true,
            systemImage: "building.2.fill",
            actionTitle: nil
        ),
        .towerFloorCount: SmartTip(
            id: .towerFloorCount,
            title: "Floor Count Controls Delivery",
            message: "The selected tower controls how HimmerFlow divides delivery. A 15-floor tower gets a different plan than a 32-floor tower.",
            category: .tower,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "list.number",
            actionTitle: nil
        ),
        .towerFloorCountFormula: SmartTip(
            id: .towerFloorCountFormula,
            title: "How floor count works",
            message: "HimmerFlow counts from the starting floor through the top floor, including both numbers. Example: floor 3 through floor 31 is 29 floors. If Skip 13th floor is on and floor 13 is inside that range, HimmerFlow subtracts 1, so 3–31 becomes 28 delivery floors.",
            category: .tower,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "function",
            actionTitle: nil
        ),
        .receivingPhysicalCount: SmartTip(
            id: .receivingPhysicalCount,
            title: "Physical Count Is Source of Truth",
            message: "Enter what you physically verified. Invoice or label numbers can help, but the final calculation should use actual received supply.",
            category: .receiving,
            priority: .important,
            allowsAutoOpen: true,
            systemImage: "checkmark.seal.fill",
            actionTitle: nil
        ),
        .bathTowelFixedBin: SmartTip(
            id: .bathTowelFixedBin,
            title: "Bath Towel Fixed Bin",
            message: "Bath Towel uses a fixed-bin rule: 1 full bin = 245 pcs. Enter full bins received and HimmerFlow converts bins to pieces and bundles.",
            category: .receiving,
            priority: .important,
            allowsAutoOpen: true,
            systemImage: "archivebox.fill",
            actionTitle: nil
        ),
        .manualPiecesSourceOfTruth: SmartTip(
            id: .manualPiecesSourceOfTruth,
            title: "Total Pieces for Manual Items",
            message: "For most items, enter total pieces received. Optional bin count is for carrying and tracking only.",
            category: .receiving,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "number.circle.fill",
            actionTitle: nil
        ),
        .optionalPhysicalBins: SmartTip(
            id: .optionalPhysicalBins,
            title: "Physical Bins Are Optional",
            message: "Physical bin count helps carry and elevator planning. It does not replace the received piece count.",
            category: .receiving,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "shippingbox.fill",
            actionTitle: nil
        ),
        .reviewBeforeCalculate: SmartTip(
            id: .reviewBeforeCalculate,
            title: "Review Before Calculating",
            message: "Use this checkpoint to catch wrong bin counts, wrong item names, or missing pieces before HimmerFlow builds the delivery plan.",
            category: .review,
            priority: .important,
            allowsAutoOpen: true,
            systemImage: "checklist",
            actionTitle: nil
        ),
        .bundleFirstDisplay: SmartTip(
            id: .bundleFirstDisplay,
            title: "Bundles Come First",
            message: "Bundles are shown first because they are the deliverable unit. Pieces are still shown as helper detail.",
            category: .bundles,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "shippingbox.fill",
            actionTitle: nil
        ),
        .loosePieces: SmartTip(
            id: .loosePieces,
            title: "Loose Pieces Stay Separate",
            message: "Loose pieces are leftovers after making full bundles. By default, HimmerFlow does not deliver loose pieces as bundles.",
            category: .bundles,
            priority: .important,
            allowsAutoOpen: true,
            systemImage: "circle.grid.2x2.fill",
            actionTitle: nil
        ),
        .resultsMeaning: SmartTip(
            id: .resultsMeaning,
            title: "Reading Results",
            message: "Results compare received supply against the tower's par need. Received is what came in, required is the par target, and difference shows shortage, exact, or extra.",
            category: .results,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "function",
            actionTitle: nil
        ),
        .shortage: SmartTip(
            id: .shortage,
            title: "Shortage",
            message: "Shortage means received supply is below the tower's par target. HimmerFlow will still plan from available supply and show what is missing.",
            category: .results,
            priority: .warning,
            allowsAutoOpen: true,
            systemImage: "exclamationmark.triangle.fill",
            actionTitle: nil
        ),
        .overage: SmartTip(
            id: .overage,
            title: "Overage",
            message: "Overage means received supply is above par. By default, HimmerFlow does not over-deliver beyond par unless an override is used.",
            category: .results,
            priority: .important,
            allowsAutoOpen: true,
            systemImage: "arrow.up.circle.fill",
            actionTitle: nil
        ),
        .floorPlanBasics: SmartTip(
            id: .floorPlanBasics,
            title: "Floor Plan",
            message: "The floor plan shows what to deliver to each floor. Matching floors are grouped so the walking plan stays easy to scan.",
            category: .floorPlan,
            priority: .important,
            allowsAutoOpen: true,
            systemImage: "building.columns.fill",
            actionTitle: nil
        ),
        .groupedFloorRanges: SmartTip(
            id: .groupedFloorRanges,
            title: "Grouped Floor Ranges",
            message: "Floors are grouped when they receive the same bundle amounts. This keeps the delivery plan shorter and easier to read.",
            category: .floorPlan,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "rectangle.stack.fill",
            actionTitle: nil
        ),
        .liveDeliveryOpeningPass: SmartTip(
            id: .liveDeliveryOpeningPass,
            title: "Opening Pass",
            message: "Opening Pass is for opening linen room doors first. Start with the lightest or lowest-bundle item so you can move faster with less weight.",
            category: .liveDelivery,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "key.fill",
            actionTitle: nil
        ),
        .logsAreSnapshots: SmartTip(
            id: .logsAreSnapshots,
            title: "Logs Are Snapshots",
            message: "Saved logs keep the original numbers from that day, even if tower settings, par, or bundle sizes change later.",
            category: .logs,
            priority: .important,
            allowsAutoOpen: true,
            systemImage: "doc.text.fill",
            actionTitle: nil
        ),
        .logDetailReceipt: SmartTip(
            id: .logDetailReceipt,
            title: "Log Detail",
            message: "Log Detail works like a receipt. Use it to review received supply, calculations, delivery plan, notes, and saved progress.",
            category: .logs,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "doc.plaintext.fill",
            actionTitle: nil
        ),
        .settingsFutureOnly: SmartTip(
            id: .settingsFutureOnly,
            title: "Settings Affect Future Flows",
            message: "Changes in Settings affect future calculations only. Old saved logs stay unchanged because they use snapshots.",
            category: .settings,
            priority: .important,
            allowsAutoOpen: true,
            systemImage: "gearshape.fill",
            actionTitle: nil
        ),
        .widgetItemSelection: SmartTip(
            id: .widgetItemSelection,
            title: "Widget Items",
            message: "Choose up to 3 important items for the widget. Good choices are current delivery item, progress, or shortage status.",
            category: .widget,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "pin.fill",
            actionTitle: nil
        ),
        .noTowerSelected: SmartTip(
            id: .noTowerSelected,
            title: "Choose a Tower First",
            message: "HimmerFlow needs a tower or area before it can apply floor count, par rules, and delivery planning.",
            category: .validation,
            priority: .warning,
            allowsAutoOpen: true,
            systemImage: "building.2.crop.circle",
            actionTitle: nil
        ),
        .noItemsEntered: SmartTip(
            id: .noItemsEntered,
            title: "Enter Received Linen",
            message: "Add at least one received item before reviewing, calculating, or saving a daily log.",
            category: .validation,
            priority: .warning,
            allowsAutoOpen: true,
            systemImage: "tray.and.arrow.down.fill",
            actionTitle: nil
        ),
        .invalidNumber: SmartTip(
            id: .invalidNumber,
            title: "Check the Number",
            message: "Use whole positive counts for bins or pieces. Arithmetic is allowed, but the final result must be a valid linen count.",
            category: .validation,
            priority: .warning,
            allowsAutoOpen: true,
            systemImage: "number",
            actionTitle: nil
        ),
        .saveLogSnapshot: SmartTip(
            id: .saveLogSnapshot,
            title: "Save Daily Log",
            message: "Saving creates a snapshot of the current flow, including entries, calculations, delivery plan, and notes when available.",
            category: .logs,
            priority: .normal,
            allowsAutoOpen: true,
            systemImage: "tray.and.arrow.down.fill",
            actionTitle: nil
        )
    ]
}
