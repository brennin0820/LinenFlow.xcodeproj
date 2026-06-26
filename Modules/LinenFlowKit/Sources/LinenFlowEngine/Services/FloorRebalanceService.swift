import Foundation
import LinenFlowCore

public enum FloorRebalanceError: LocalizedError, Equatable {
    case emptyItemName
    case negativeOriginalPCS
    case invalidTotalFloors
    case missingOriginalPlan
    case invalidShortRange
    case shortRangeOutOfBounds
    case negativeShortFloorPCS
    case invalidOverrideRange
    case overrideRangeOutOfBounds
    case negativeOverridePCS
    case overlappingOverrideFloor(Int)
    case duplicateFloor(Int)
    case missingFloor(Int)

    public var errorDescription: String? {
        switch self {
        case .emptyItemName:
            return "Select an item before rebalancing."
        case .negativeOriginalPCS:
            return "Original PCS cannot be negative."
        case .invalidTotalFloors:
            return "Total floors must be greater than zero."
        case .missingOriginalPlan:
            return "No original floor plan was found for this item."
        case .invalidShortRange:
            return "Short floor start must be before or equal to short floor end."
        case .shortRangeOutOfBounds:
            return "Short floor range must stay inside the tower floor count."
        case .negativeShortFloorPCS:
            return "PCS on short floors cannot be negative."
        case .invalidOverrideRange:
            return "Each override range must start before or on its ending floor."
        case .overrideRangeOutOfBounds:
            return "Override ranges must stay inside the tower floor count."
        case .negativeOverridePCS:
            return "Override PCS cannot be negative."
        case .overlappingOverrideFloor(let floor):
            return "Override ranges overlap on floor \(floor)."
        case .duplicateFloor(let floor):
            return "Original floor plan contains duplicate floor \(floor)."
        case .missingFloor(let floor):
            return "Original floor plan is missing floor \(floor)."
        }
    }
}

public struct FloorRebalanceService {
    public func rebalanceShortFloors(_ request: FloorRebalanceRequest) throws -> FloorRebalanceResult {
        try validate(request)

        var currentPCSByFloor = Dictionary(
            uniqueKeysWithValues: request.originalPlan
                .filter { $0.itemName == request.itemName }
                .map { ($0.floorNumber, max(0, $0.suggestedPieces)) }
        )

        for override in overrideRanges(for: request) {
            for floor in override.startFloor...override.endFloor {
                currentPCSByFloor[floor] = override.pcsEach
            }
        }

        let actualPCS = (1...request.totalFloors).reduce(0) { total, floor in
            total + (currentPCSByFloor[floor] ?? 0)
        }
        let baseTarget = actualPCS / request.totalFloors
        let remainder = actualPCS % request.totalFloors

        let targets = (1...request.totalFloors).map { floor in
            let currentPCS = currentPCSByFloor[floor] ?? 0
            let targetPCS = floor <= remainder ? baseTarget + 1 : baseTarget
            return FloorRebalanceTarget(
                floorNumber: floor,
                currentPCS: currentPCS,
                targetPCS: targetPCS,
                delta: currentPCS - targetPCS
            )
        }

        let groupedActions = groupTargets(targets)
        let groupedFinalTargets = groupFinalTargets(targets)
        let totalCollectBackPCS = groupedActions
            .filter { $0.actionType == .collectBack }
            .reduce(0) { $0 + $1.totalPCS }
        let totalDeliverPCS = groupedActions
            .filter { $0.actionType == .deliver }
            .reduce(0) { $0 + $1.totalPCS }

        return FloorRebalanceResult(
            itemName: request.itemName,
            originalPCS: request.originalPCS,
            actualPCS: actualPCS,
            missingPCS: request.originalPCS - actualPCS,
            totalFloors: request.totalFloors,
            baseTarget: baseTarget,
            remainder: remainder,
            targets: targets,
            groupedActions: groupedActions,
            groupedFinalTargets: groupedFinalTargets,
            totalCollectBackPCS: totalCollectBackPCS,
            totalDeliverPCS: totalDeliverPCS,
            isBalanced: totalCollectBackPCS == totalDeliverPCS
        )
    }

    private func validate(_ request: FloorRebalanceRequest) throws {
        let itemName = request.itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !itemName.isEmpty else { throw FloorRebalanceError.emptyItemName }
        guard request.originalPCS >= 0 else { throw FloorRebalanceError.negativeOriginalPCS }
        guard request.totalFloors > 0 else { throw FloorRebalanceError.invalidTotalFloors }
        try validateOverrides(for: request)

        let itemRows = request.originalPlan.filter { $0.itemName == request.itemName }
        guard !itemRows.isEmpty else { throw FloorRebalanceError.missingOriginalPlan }

        var seenFloors: Set<Int> = []
        for row in itemRows {
            guard !seenFloors.contains(row.floorNumber) else {
                throw FloorRebalanceError.duplicateFloor(row.floorNumber)
            }
            seenFloors.insert(row.floorNumber)
        }

        for floor in 1...request.totalFloors where !seenFloors.contains(floor) {
            throw FloorRebalanceError.missingFloor(floor)
        }
    }

    private func overrideRanges(for request: FloorRebalanceRequest) -> [FloorRebalanceOverrideRange] {
        if !request.manualOverrideRanges.isEmpty {
            return request.manualOverrideRanges
        }
        return [
            FloorRebalanceOverrideRange(
                startFloor: request.shortFloorStart,
                endFloor: request.shortFloorEnd,
                pcsEach: request.pcsOnShortFloors
            )
        ]
    }

    private func validateOverrides(for request: FloorRebalanceRequest) throws {
        if request.manualOverrideRanges.isEmpty {
            guard request.shortFloorStart <= request.shortFloorEnd else { throw FloorRebalanceError.invalidShortRange }
            guard request.shortFloorStart >= 1, request.shortFloorEnd <= request.totalFloors else {
                throw FloorRebalanceError.shortRangeOutOfBounds
            }
            guard request.pcsOnShortFloors >= 0 else { throw FloorRebalanceError.negativeShortFloorPCS }
            return
        }

        var overriddenFloors: Set<Int> = []
        for override in request.manualOverrideRanges {
            guard override.startFloor <= override.endFloor else { throw FloorRebalanceError.invalidOverrideRange }
            guard override.startFloor >= 1, override.endFloor <= request.totalFloors else {
                throw FloorRebalanceError.overrideRangeOutOfBounds
            }
            guard override.pcsEach >= 0 else { throw FloorRebalanceError.negativeOverridePCS }

            for floor in override.startFloor...override.endFloor {
                guard !overriddenFloors.contains(floor) else {
                    throw FloorRebalanceError.overlappingOverrideFloor(floor)
                }
                overriddenFloors.insert(floor)
            }
        }
    }

    private func groupTargets(_ targets: [FloorRebalanceTarget]) -> [FloorRebalanceAction] {
        group(targets) { target in
            if target.delta > 0 {
                return (.collectBack, target.delta)
            }
            if target.delta < 0 {
                return (.deliver, abs(target.delta))
            }
            return (.noChange, 0)
        }
    }

    private func groupFinalTargets(_ targets: [FloorRebalanceTarget]) -> [FloorRebalanceAction] {
        group(targets) { target in
            (.noChange, target.targetPCS)
        }
    }

    private func group(
        _ targets: [FloorRebalanceTarget],
        key: (FloorRebalanceTarget) -> (FloorRebalanceActionType, Int)
    ) -> [FloorRebalanceAction] {
        var actions: [FloorRebalanceAction] = []

        for target in targets {
            let (actionType, pcsEach) = key(target)
            if let last = actions.last,
               last.endFloor + 1 == target.floorNumber,
               last.actionType == actionType,
               last.pcsEach == pcsEach {
                actions[actions.count - 1].endFloor = target.floorNumber
                actions[actions.count - 1].totalPCS += pcsEach
            } else {
                actions.append(FloorRebalanceAction(
                    startFloor: target.floorNumber,
                    endFloor: target.floorNumber,
                    actionType: actionType,
                    pcsEach: pcsEach,
                    totalPCS: pcsEach
                ))
            }
        }

        return actions
    }
}
