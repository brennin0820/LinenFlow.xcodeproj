import AppIntents
import ActivityKit
import WidgetKit

enum HimmerFlowWidgetDisplayMode: String, AppEnum {
    case shiftStatus
    case floorProgress
    case nextCarry

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Display Mode"
    }

    static var caseDisplayRepresentations: [HimmerFlowWidgetDisplayMode: DisplayRepresentation] {
        [
            .shiftStatus: "Shift Status",
            .floorProgress: "Floor Progress",
            .nextCarry: "Next Carry"
        ]
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "HimmerFlow Widget" }
    static var description: IntentDescription {
        "Choose what HimmerFlow status this widget shows."
    }

    @Parameter(title: "Display Mode", default: .shiftStatus)
    var displayMode: HimmerFlowWidgetDisplayMode
}

@available(iOS 16.1, *)
struct CompleteCurrentFloorIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Floor"
    private static let widgetKind = "HimmerFlow_Widget"
    private static let pendingCountKey = "pendingLiveActivityDrops"
    private static let pendingFloorsKey = "pendingLiveActivityDropFloors"

    @Parameter(title: "Displayed Floor")
    var displayedFloorNumber: Int?
    
    init() {}

    init(floorNumber: Int?) {
        self.displayedFloorNumber = floorNumber
    }
    
    func perform() async throws -> some IntentResult {
        var sharedState = SharedWidgetStateManager.load()
        let completedFloor = Self.currentFloor(in: sharedState, requestedFloor: displayedFloorNumber)

        if let completedFloor {
            sharedState = Self.completing(floor: completedFloor, in: sharedState)
            SharedWidgetStateManager.save(sharedState)
            Self.queueCompletedFloor(completedFloor)
            WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
            await Self.updateLiveActivities(from: sharedState)
        } else {
            WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
            await Self.updateLiveActivities(from: sharedState)
        }

        return .result()
    }

    static func updateLiveActivities(from sharedState: SharedWidgetState) async {
        for activity in Activity<HimmerFlowDeliveryAttributes>.activities {
            var newState = activity.content.state
            newState.completedFloors = sharedState.completedFloors
            newState.remainingFloors = sharedState.remainingFloors
            newState.currentItemName = sharedState.currentItemName
            newState.currentItemNames = sharedState.currentItemNames
            newState.currentTripItemNames = sharedState.currentTripItemNames
            newState.currentFloorNumber = sharedState.currentFloorNumber
            newState.currentFloorDeliveryAmounts = sharedState.currentFloorDeliveryAmounts
            newState.currentTripRemainingBundles = sharedState.currentTripRemainingBundles
            newState.currentTripTotalBundles = sharedState.currentTripTotalBundles
            newState.nextCarryGroupTitle = sharedState.nextCarryGroupTitle

            if newState.remainingFloors == 0 {
                newState.statusText = "Delivery complete"
                newState.isActiveSession = false
            } else {
                newState.statusText = sharedState.statusText
                newState.isActiveSession = sharedState.isActiveSession
            }

            newState.lastUpdated = .now
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
        }
    }

    private static func currentFloor(in state: SharedWidgetState, requestedFloor: Int?) -> Int? {
        let completed = Set(state.completedFloorNumbers ?? [])
        if let requestedFloor, completed.contains(requestedFloor) {
            return nil
        }
        if let current = state.currentFloorNumber, !completed.contains(current) {
            if let requestedFloor, requestedFloor != current {
                return nil
            }
            return current
        }
        let resolved = state.deliveryFloorNumbers?.first { !completed.contains($0) }
        if let requestedFloor, requestedFloor != resolved {
            return nil
        }
        return resolved
    }

    private static func completing(floor: Int, in state: SharedWidgetState) -> SharedWidgetState {
        var newState = state
        var completed = Set(newState.completedFloorNumbers ?? [])
        completed.insert(floor)

        let floors = newState.deliveryFloorNumbers ?? []
        let floorCount = floors.isEmpty ? max(newState.floorCount, completed.count) : floors.count
        let nextFloor = floors.first { !completed.contains($0) }

        newState.completedFloorNumbers = Array(completed).sorted()
        newState.completedFloors = floors.isEmpty ? min(newState.completedFloors + 1, floorCount) : completed.intersection(Set(floors)).count
        newState.floorCount = floorCount
        newState.remainingFloors = max(floorCount - newState.completedFloors, 0)
        newState.currentFloorNumber = nextFloor
        newState.currentFloorDeliveryAmounts = nextFloor.flatMap { newState.floorDeliveryAmountsByFloor?[$0] }
        let floorBundles = Self.bundleCount(onFloor: floor, in: newState)
        if let remainingBundles = newState.currentTripRemainingBundles {
            newState.currentTripRemainingBundles = max(remainingBundles - floorBundles, 0)
        }
        newState.isActiveSession = nextFloor != nil && newState.isActiveSession
        newState.lastCompletedFloorNumber = floor
        newState.statusText = nextFloor.map { "Floor \($0)" } ?? "Delivery complete"
        newState.lastUpdated = .now
        return newState
    }

    static func bundleCount(onFloor floor: Int, in state: SharedWidgetState) -> Int {
        (state.floorDeliveryAmountsByFloor?[floor] ?? []).reduce(0) { $0 + max($1.bundles, 0) }
    }

    private static func queueCompletedFloor(_ floor: Int) {
        if let defaults = UserDefaults(suiteName: SharedWidgetStateManager.appGroupID) {
            var floors = defaults.array(forKey: Self.pendingFloorsKey) as? [Int] ?? []
            if floors.last != floor {
                floors.append(floor)
            }
            defaults.set(floors, forKey: Self.pendingFloorsKey)

            defaults.set(floors.count, forKey: Self.pendingCountKey)
            defaults.synchronize()
        }
    }
}

@available(iOS 16.1, *)
typealias LogDeliveryDropIntent = CompleteCurrentFloorIntent

@available(iOS 16.1, *)
struct UndoLastFloorIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Undo Last Floor"
    private static let widgetKind = "HimmerFlow_Widget"
    private static let pendingUndoFloorsKey = "pendingLiveActivityUndoFloors"

    init() {}

    func perform() async throws -> some IntentResult {
        var sharedState = SharedWidgetStateManager.load()
        guard let floor = sharedState.lastCompletedFloorNumber else {
            return .result()
        }

        sharedState = Self.undoing(floor: floor, in: sharedState)
        SharedWidgetStateManager.save(sharedState)
        Self.queueUndoFloor(floor)
        WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
        await CompleteCurrentFloorIntent.updateLiveActivities(from: sharedState)
        return .result()
    }

    private static func undoing(floor: Int, in state: SharedWidgetState) -> SharedWidgetState {
        var newState = state
        var completed = Set(newState.completedFloorNumbers ?? [])
        completed.remove(floor)

        let floors = newState.deliveryFloorNumbers ?? []
        let floorCount = floors.isEmpty ? newState.floorCount : floors.count

        newState.completedFloorNumbers = Array(completed).sorted()
        newState.completedFloors = floors.isEmpty ? max(newState.completedFloors - 1, 0) : completed.intersection(Set(floors)).count
        newState.floorCount = floorCount
        newState.remainingFloors = max(floorCount - newState.completedFloors, 0)
        newState.currentFloorNumber = floor
        newState.currentFloorDeliveryAmounts = newState.floorDeliveryAmountsByFloor?[floor]
        let floorBundles = CompleteCurrentFloorIntent.bundleCount(onFloor: floor, in: newState)
        if let remainingBundles = newState.currentTripRemainingBundles,
           let totalBundles = newState.currentTripTotalBundles {
            newState.currentTripRemainingBundles = min(remainingBundles + floorBundles, totalBundles)
        }
        newState.isActiveSession = floorCount > 0
        newState.lastCompletedFloorNumber = nil
        newState.statusText = "Floor \(floor)"
        newState.lastUpdated = .now
        return newState
    }

    private static func queueUndoFloor(_ floor: Int) {
        guard let defaults = UserDefaults(suiteName: SharedWidgetStateManager.appGroupID) else { return }
        var floors = defaults.array(forKey: Self.pendingUndoFloorsKey) as? [Int] ?? []
        if floors.last != floor {
            floors.append(floor)
        }
        defaults.set(floors, forKey: Self.pendingUndoFloorsKey)
        defaults.synchronize()
    }
}
