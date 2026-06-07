import Foundation

enum LinenCalculatorService {

    static func calculateReceivedPieces(entry: ReceivingEntry) -> Int {
        switch entry.countMethod {
        case .fixedBin:
            let bins = max(0, entry.binCount ?? 0)
            let perBin = max(0, entry.piecesPerBin ?? 0)
            return bins * perBin
        case .manualPieces, .cartLabelPieces:
            return max(0, entry.manualPieces ?? 0)
        }
    }

    static func convertPiecesToBundles(pieces: Int, bundleSize: Int) -> (fullBundles: Int, loosePieces: Int) {
        let conversion = BundleDistributionAlgorithm.convertPiecesToBundles(
            pieces: pieces,
            bundleSize: bundleSize
        )
        return (conversion.fullBundles, conversion.loosePieces)
    }

    static func calculateRequiredPieces(floorCount: Int, parCount: Int) -> Int {
        max(0, floorCount) * max(0, parCount)
    }

    static func calculateDifference(receivedPieces: Int, requiredPieces: Int) -> Int {
        receivedPieces - requiredPieces
    }

    static func calculateStatus(difference: Int) -> CalculationStatus {
        if difference > 0 { return .overage }
        if difference < 0 { return .shortage }
        return .exact
    }

    static func calculateExactPerFloor(receivedPieces: Int, floorCount: Int) -> Double {
        guard floorCount > 0 else { return 0 }
        return Double(receivedPieces) / Double(floorCount)
    }

    static func calculateBasePerFloor(receivedPieces: Int, floorCount: Int) -> Int {
        guard floorCount > 0 else { return 0 }
        return max(0, receivedPieces) / floorCount
    }

    static func calculateRemainder(receivedPieces: Int, floorCount: Int) -> Int {
        guard floorCount > 0 else { return 0 }
        return max(0, receivedPieces) % floorCount
    }

    /// Per-floor piece distribution. First `remainder` floors get `base + 1`, the rest get `base`.
    static func calculateFloorDistribution(
        receivedPieces: Int,
        floorCount: Int,
        itemName: String
    ) -> [FloorDistributionRow] {
        guard floorCount > 0 else { return [] }
        let safe = max(0, receivedPieces)
        let base = safe / floorCount
        let remainder = safe % floorCount
        return (1...floorCount).map { floor in
            let extra = floor <= remainder ? 1 : 0
            return FloorDistributionRow(
                floorNumber: floor,
                itemName: itemName,
                suggestedPieces: base + extra
            )
        }
    }

    /// Whole-bundle per-floor distribution. Loose pieces are NOT included — they're surfaced separately.
    static func calculateBundleFloorDistribution(
        fullBundles: Int,
        floorCount: Int,
        itemName: String
    ) -> [FloorDistributionRow] {
        BundleDistributionAlgorithm.distributeBundles(
            fullBundles: fullBundles,
            floorCount: floorCount,
            itemName: itemName
        )
    }

    static func calculateBundleDeliveryPlan(
        fullBundles: Int,
        floorCount: Int,
        parPerFloor: Int
    ) -> (maxAllowedBundles: Int, deliverableBundles: Int, shortageBundles: Int, leftoverBundles: Int) {
        BundleDistributionAlgorithm.deliveryPlan(
            fullBundles: fullBundles,
            floorCount: floorCount,
            parPerFloor: parPerFloor
        )
    }

    static func calculateCappedBundleFloorDistribution(
        fullBundles: Int,
        floorCount: Int,
        parPerFloor: Int,
        itemName: String
    ) -> [FloorDistributionRow] {
        BundleDistributionAlgorithm.distributeBundlesWithParCap(
            fullBundles: fullBundles,
            floorCount: floorCount,
            parPerFloor: parPerFloor,
            itemName: itemName
        ).rows
    }

    static func calculateSummary(
        itemName: String,
        receivedPieces: Int,
        floorCount: Int,
        parCount: Int,
        bundleSize: Int
    ) -> CalculationSummary {
        let (fullBundles, loosePieces) = convertPiecesToBundles(pieces: receivedPieces, bundleSize: bundleSize)
        let bundlePlan = calculateBundleDeliveryPlan(
            fullBundles: fullBundles,
            floorCount: floorCount,
            parPerFloor: parCount
        )
        let requiredPieces = calculateRequiredPieces(floorCount: floorCount, parCount: parCount)
        let requiredBundles: Int? = bundleSize > 0 ? requiredPieces / bundleSize : nil
        let difference = calculateDifference(receivedPieces: receivedPieces, requiredPieces: requiredPieces)
        let differenceBundles: Int = bundleSize > 0 ? difference / bundleSize : 0
        let status = calculateStatus(difference: difference)
        let exactPerFloor = calculateExactPerFloor(receivedPieces: receivedPieces, floorCount: floorCount)
        let basePerFloor = calculateBasePerFloor(receivedPieces: receivedPieces, floorCount: floorCount)
        let remainder = calculateRemainder(receivedPieces: receivedPieces, floorCount: floorCount)

        return CalculationSummary(
            itemName: itemName,
            receivedPieces: receivedPieces,
            bundleSize: bundleSize,
            fullBundles: fullBundles,
            loosePieces: loosePieces,
            requiredPieces: requiredPieces,
            requiredBundles: requiredBundles,
            maxAllowedBundles: bundlePlan.maxAllowedBundles,
            deliverableBundles: bundlePlan.deliverableBundles,
            shortageBundles: bundlePlan.shortageBundles,
            leftoverBundles: bundlePlan.leftoverBundles,
            differencePieces: difference,
            differenceBundles: differenceBundles,
            status: status,
            exactPerFloorPieces: exactPerFloor,
            basePerFloorPieces: basePerFloor,
            remainderPieces: remainder
        )
    }

    static func calculateNoParSummary(
        itemName: String,
        receivedPieces: Int,
        floorCount: Int,
        bundleSize: Int
    ) -> CalculationSummary {
        let (fullBundles, loosePieces) = convertPiecesToBundles(pieces: receivedPieces, bundleSize: bundleSize)
        let exactPerFloor = calculateExactPerFloor(receivedPieces: receivedPieces, floorCount: floorCount)
        let basePerFloor = calculateBasePerFloor(receivedPieces: receivedPieces, floorCount: floorCount)
        let remainder = calculateRemainder(receivedPieces: receivedPieces, floorCount: floorCount)

        return CalculationSummary(
            itemName: itemName,
            receivedPieces: receivedPieces,
            bundleSize: bundleSize,
            fullBundles: fullBundles,
            loosePieces: loosePieces,
            requiredPieces: receivedPieces,
            requiredBundles: fullBundles,
            maxAllowedBundles: fullBundles,
            deliverableBundles: fullBundles,
            shortageBundles: 0,
            leftoverBundles: 0,
            differencePieces: 0,
            differenceBundles: 0,
            status: .exact,
            exactPerFloorPieces: exactPerFloor,
            basePerFloorPieces: basePerFloor,
            remainderPieces: remainder
        )
    }
}
