import Foundation

struct BundleConversion {
    let fullBundles: Int
    let loosePieces: Int
}

struct BundleDistributionResult {
    let rows: [FloorDistributionRow]
    let maxAllowedBundles: Int
    let deliverableBundles: Int
    let shortageBundles: Int
    let leftoverBundles: Int
}

enum BundleDistributionAlgorithm {
    static func convertPiecesToBundles(pieces: Int, bundleSize: Int) -> BundleConversion {
        let safePieces = max(0, pieces)
        guard bundleSize > 0 else {
            return BundleConversion(fullBundles: 0, loosePieces: safePieces)
        }
        return BundleConversion(
            fullBundles: safePieces / bundleSize,
            loosePieces: safePieces % bundleSize
        )
    }

    static func deliveryPlan(
        fullBundles: Int,
        floorCount: Int,
        parPerFloor: Int
    ) -> (maxAllowedBundles: Int, deliverableBundles: Int, shortageBundles: Int, leftoverBundles: Int) {
        let safeFullBundles = max(0, fullBundles)
        let maxAllowedBundles = max(0, floorCount) * max(0, parPerFloor)
        let deliverableBundles = min(safeFullBundles, maxAllowedBundles)
        let shortageBundles = max(0, maxAllowedBundles - safeFullBundles)
        let leftoverBundles = max(0, safeFullBundles - maxAllowedBundles)
        return (maxAllowedBundles, deliverableBundles, shortageBundles, leftoverBundles)
    }

    static func distributeBundles(fullBundles: Int, floorCount: Int, itemName: String) -> [FloorDistributionRow] {
        guard floorCount > 0 else { return [] }
        let safeBundles = max(0, fullBundles)
        let base = safeBundles / floorCount
        let remainder = safeBundles % floorCount

        return (1...floorCount).map { floor in
            let extra = floor <= remainder ? 1 : 0
            return FloorDistributionRow(
                floorNumber: floor,
                itemName: itemName,
                suggestedPieces: 0,
                suggestedBundles: base + extra
            )
        }
    }

    static func distributeBundlesWithParCap(
        fullBundles: Int,
        floorCount: Int,
        parPerFloor: Int,
        itemName: String
    ) -> BundleDistributionResult {
        let plan = deliveryPlan(
            fullBundles: fullBundles,
            floorCount: floorCount,
            parPerFloor: parPerFloor
        )
        let rows = distributeBundles(
            fullBundles: plan.deliverableBundles,
            floorCount: floorCount,
            itemName: itemName
        )
        return BundleDistributionResult(
            rows: rows,
            maxAllowedBundles: plan.maxAllowedBundles,
            deliverableBundles: plan.deliverableBundles,
            shortageBundles: plan.shortageBundles,
            leftoverBundles: plan.leftoverBundles
        )
    }
}
